#!/usr/bin/env perl

use Modern::Perl;

use IO::Socket;
use IO::Select;
use IO::Handle;
use Net::SOCKS;

#use EV;
use AnyEvent::Impl::Perl;
use AnyEvent;

use Config::Tiny;
use Storable qw( store retrieve freeze thaw );
use MTProto;

use Data::Dumper;
#use Devel::Gladiator qw/ walk_arena /;

my $conf = Config::Tiny->read("teleperl.conf");

my ($idle, $timer, $signal);
my %sessions;

my $cond = AnyEvent->condvar;

# Layer and Connection
use Telegram::InvokeWithLayer;
use Telegram::InitConnection;

use Telegram::Help::GetConfig;
use MTProto::Ping;
use Telegram::Auth::SendCode;
use Telegram::Auth::SentCode;
use Telegram::Auth::SignIn;

# new connection
my $proxy = new Net::SOCKS( socks_addr => $conf->{proxy}{addr},
    socks_port => $conf->{proxy}{port}, 
    user_id => $conf->{proxy}{user},
    user_password => $conf->{proxy}{pass}, 
    protocol_version => 5,
);

say "connect";
my $sock = $proxy->connect( peer_addr => $conf->{dc}{addr}, peer_port => $conf->{dc}{port} ) or die;
    
#my $sock = IO::Socket::INET->new(
#    PeerAddr => $conf->{dc}{addr}, 
#    PeerPort => $conf->{dc}{port},
#    Proto => 'tcp'
#) or die;

# this creates new MTProto session
#my $mt = MTProto->new( socket => $sock, session => undef, debug => 1 );
my $mt = MTProto->new( socket => AnyEvent::Handle->new( fh => $sock ), session => undef, debug => 1 );
$mt->start_session;

# The Query
my $query = Telegram::Auth::SendCode->new( phone_number => $conf->{user}{phone},
        api_id => $conf->{app}{api_id},
        api_hash => $conf->{app}{api_hash},
        flags => 0
);

# Wrapper conn
my $conn = Telegram::InitConnection->new( 
        api_id => $conf->{app}{api_id},
        device_model => 'IBM PC/AT',
        system_version => 'DOS 6.22',
        app_version => '0.01',
        system_lang_code => 'en',
        lang_pack => '',
        lang_code => 'en',
        query => $query
);
say 'invoke';
# Wrapper layer
$mt->invoke( Telegram::InvokeWithLayer->new( layer => 78, query => $conn ) );

$mt->{on_message} = sub {
    my $msg = shift;
    if ($msg->{object}->isa('MTProto::NewSessionCreated')){
        say STDERR "session created";
    }
    elsif ($msg->{object}->isa('MTProto::RpcResult')) {
        say Dumper $msg->{object};
        my $res = $msg->{object}{result};
        if ( $res->isa('Telegram::Auth::SentCode') ){
            say "code sent, ", ref $res->{type};
            say "enter code";
            chomp( my $pc = <> );

            my $signin = Telegram::Auth::SignIn->new;
            $signin->{phone_number} = $conf->{user}{phone};
            $signin->{phone_code_hash} = $res->{phone_code_hash};
            $signin->{phone_code} = $pc;

            $mt->invoke( $signin );
        }
        elsif ($res->isa('Telegram::Auth::Authorization') ){
            say "auth ok";
        }
        else {
            say Dumper $msg->{object};
        }
    }
    else {
        say Dumper $msg->{object};
    }
};

$signal = AnyEvent->signal( signal => 'INT', cb => sub {
        say STDERR "INT recvd";
        store( {mtproto => $mt->{session}}, 'session.dat');
        $cond->send;
    } );

$cond->recv;


