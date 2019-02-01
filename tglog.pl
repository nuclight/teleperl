use Modern::Perl;
use utf8;

use Config::Tiny;
use Storable qw( store retrieve freeze thaw );

use AnyEvent::Impl::Perl;
use AnyEvent;

use Telegram;
use Telegram::Messages::GetDialogs;
use Telegram::Messages::GetHistory;
use Telegram::InputPeer;

use DBIx::Class;
use Teleblog::Schema;
use DateTime;

use Data::Dumper;
use Devel::StackTrace;

$SIG{__DIE__} = sub { 
	my $error = shift; 
	my $trace = Devel::StackTrace->new; 
	print "Error: $error\n", "Stack Trace:\n", $trace->as_string;
};

my $deep_hist = shift @ARGV;

my $schema = Teleblog::Schema->connect(
	'dbi:mysql:teleblog:localhost:3306',
	'teleblog', 'VeloRuhe', {
		quote_names => 1,
		mysql_enable_utf8 => 1,
});

sub handle_update
{
    my ($schema, $tg, $upd) = @_;

    if ( $upd->isa('MTProto::RpcError') ) {
        say "\rRpcError $upd->{error_code}: $upd->{error_message}";
    }
    if ( $upd->isa('Telegram::Message') ) {
        my $name = defined $upd->{from_id} ? $tg->peer_name($upd->{from_id}) : '';
        my $to = $upd->{to_id};
        my $from = $upd->{from_id};
        my $to_verb;
        if ($to) {
            if ($to->isa('Telegram::PeerChannel')) {
                $to = $to->{channel_id};
            }
            if ($to->isa('Telegram::PeerChat')) {
                $to = $to->{chat_id};
            }
	    $to_verb = $tg->peer_name($to);
        }
        $to_verb = $to_verb ? " in $to_verb" : '';

        my @t = localtime;
        print "\r[", join(":", map {"0"x(2-length).$_} reverse @t[0..2]), "] ";
        say "$name$to_verb: $upd->{message}";
        #say Dumper $upd;
        my $mesg = $upd->{message};
        utf8::decode($mesg);
        $schema->resultset('Message')->find_or_create({
            id => $upd->{id},
            from_id => $from,
            to_id => $to,
            message => $mesg,
            date => DateTime->from_epoch(epoch => $upd->{date})
        }, key => 'msg_id');
    }
}

sub handle_history
{
    my ($tg, $ipeer, $first_id, $last_id, $deep, $ms) = @_;

    if ($ms->isa('Telegram::Messages::ChannelMessages')) {
        my $top_m = 0;

        for my $u (@{$ms->{users}}) {
            if ($u->isa('Telegram::User')) {
                my $user = $schema->resultset('User')->find($u->{id});
                $schema->resultset('User')->create({
                    id => $u->{id},
                    first_name => $u->{first_name},
                    last_name => $u->{last_name},
                    username => $u->{username}
	    	}) unless $user;
            }
        }
        for my $m (@{$ms->{messages}}) {
            if ($m->isa('Telegram::Message')) {
                $top_m = $m->{id};
                my $to = $m->{to_id};
                my $from = $m->{from_id};
                if ($to) {
                    if ($to->isa('Telegram::PeerChannel')) {
                        $to = $to->{channel_id};
                    }
                    if ($to->isa('Telegram::PeerChat')) {
                        $to = $to->{chat_id};
                    }
                }

                say "id: $m->{id}";
                my $mesg = $m->{message};
                utf8::decode($mesg);
                $schema->resultset('Message')->find_or_create({
                    id => $m->{id},
                    from_id => $from,
                    to_id => $to,
                    message => $mesg,
                    date => DateTime->from_epoch(epoch => $m->{date})
                }, key => 'msg_id');
            }
        }
        if ($deep) {
	    if ($top_m != $first_id) {
                $tg->invoke( 
                    Telegram::Messages::GetHistory->new(
                        peer => $ipeer,
                        offset_id => $top_m,
                        offset_date => 0,
                        add_offset => 0,
                        limit => 20,
                        max_id => 0,
                        min_id => 0,
                        hash => 0
                    ), 
                    sub { handle_history($tg, $ipeer, $top_m, $last_id, 1, @_) } 
                );
	    }
        }
        else {
            if ($top_m > $last_id) {
                $tg->invoke( 
                    Telegram::Messages::GetHistory->new(
                        peer => $ipeer,
                        offset_id => $top_m,
                        offset_date => 0,
                        add_offset => 0,
                        limit => 20,
                        max_id => 0,
                        min_id => 0,
                        hash => 0
                    ), 
                    sub { handle_history($tg, $ipeer, $first_id, $last_id, 0, @_) } 
                );
            }
        }
    }
    else {
	    say Dumper $ms;
    }
}

sub get_chan_history
{
    my ($tg, $ipeer, $top_m) = @_;

    my $last = $schema->resultset('Message')->search(
        { to_id => $ipeer->{channel_id}, }, 
        {   order_by => { -desc => 'id' },
            rows => 1,
            columns => ['id']
        } )->single;
    my $first = $schema->resultset('Message')->search(
        { to_id => $ipeer->{channel_id}, }, 
        {   order_by => { -asc => 'id' },
            rows => 1,
            columns => ['id']
        } )->single;
    my $last_id = $last ? $last->id : 0;
    my $first_id = $first ? $first->id : 0;
    say "chan $ipeer->{channel_id} has msg $top_m, we have $first_id to $last_id";
    if ($top_m > $last_id) {
        $tg->invoke( 
            Telegram::Messages::GetHistory->new(
                peer => $ipeer,
                offset_id => 0,
                offset_date => 0,
                add_offset => 0,
                limit => 20,
                max_id => 0,
                min_id => 0,
                hash => 0
            ), 
            sub { handle_history($tg, $ipeer, $first_id, $last_id, 0, @_) } 
        );
    }
    if ($deep_hist and $first_id) {
        $tg->invoke( 
            Telegram::Messages::GetHistory->new(
                peer => $ipeer,
                offset_id => $first_id,
                offset_date => 0,
                add_offset => 0,
                limit => 20,
                max_id => 0,
                min_id => 0,
                hash => 0
            ), 
            sub { handle_history($tg, $ipeer, $first_id, $last_id, 1, @_) } 
        );
    }
}

sub handle_dialogs
{
    my ($tg, $count, $ds) = @_;

    if ($ds->isa('Telegram::Messages::DialogsABC')) {
        my %users;
        my %chats;
        my $ipeer;

        for my $u (@{$ds->{users}}) {
            $users{$u->{id}} = $u;
        }
        for my $c (@{$ds->{chats}}) {
            $chats{$c->{id}} = $c;
        }
        for my $d (@{$ds->{dialogs}}) {
            $count++;
            my $peer = $d->{peer};
            if ($peer->isa('Telegram::PeerUser')) {
                my $user_id = $peer->{user_id};
                $peer = $users{$user_id};
                say "$peer->{first_name} ". ($peer->{username} // "");
                $ipeer = Telegram::InputPeerUser->new(
                    user_id => $user_id,
                    access_hash => $peer->{access_hash}
                );
            }
            if ($peer->isa('Telegram::PeerChannel')) {
                my $chan_id = $peer->{channel_id};
                $peer = $chats{$chan_id};
                $ipeer = Telegram::InputPeerChannel->new(
                    channel_id => $chan_id,
                    access_hash => $peer->{access_hash}
                );
                say "#" , ($peer->{username} // "channel with no name o_O");
                my $chat = $schema->resultset('Chat')->find($peer->{id});
                $schema->resultset('Chat')->create({
                    id => $peer->{id},
                    title => $peer->{title},
                    username => $peer->{username}
	    	}) unless $chat;
                get_chan_history($tg, $ipeer, $d->{top_message});
            }
            if ($peer->isa('Telegram::PeerChat')){
                my $chat_id = $peer->{chat_id};
                $peer = $chats{$chat_id};
                $ipeer = Telegram::InputPeerChat->new(
                    chat_id => $chat_id,
                );
            }
        }
        if ($ds->isa('Telegram::Messages::DialogsSlice')) {
            $tg->invoke(
                Telegram::Messages::GetDialogs->new(
                    offset_id => $ds->{messages}[-1]{id},
                    offset_date => $ds->{messages}[-1]{date},
                    offset_peer => Telegram::InputPeerEmpty->new,
                    #    offset_peer => $ipeer,
                    limit => -1
                ),
                sub { handle_dialogs($tg, $count, @_) }
            ) if ($count < $ds->{count});
        }
    }
}

my $session = retrieve( 'session.dat' ) if -e 'session.dat';
my $conf = Config::Tiny->read("teleperl.conf");
    
my $tg = Telegram->new(
	dc => $conf->{dc},
	app => $conf->{app},
	proxy => $conf->{proxy},
	session => $session,
	reconnect => 1,
	keepalive => 1,
	noupdate => 0,
	debug => 0
);
$tg->{on_update} = sub { handle_update($schema, $tg, @_) };
$tg->start;

$tg->invoke(
Telegram::Messages::GetDialogs->new(
    offset_id => 0,
    offset_date => 0,
    offset_peer => Telegram::InputPeerEmpty->new,
    limit => -1
),
sub { handle_dialogs($tg, 0, @_)}
);

my $cv = AE::cv;
my $signal = AnyEvent->signal( 
	signal => 'INT', cb => sub {
        	say STDERR "INT recvd";
        	store( $tg->{session}, 'session.dat');
        	$cv->send;
    	} 
);

$cv->recv;

