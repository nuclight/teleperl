use utf8;
package Teleblog::Schema::Result::Message;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Teleblog::Schema::Result::Message

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<messages>

=cut

__PACKAGE__->table("messages");

=head1 ACCESSORS

=head2 uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 from_id

  data_type: 'bigint'
  is_nullable: 1

=head2 to_id

  data_type: 'bigint'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 flags

  data_type: 'integer'
  is_nullable: 1

=head2 date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 action

  data_type: 'text'
  is_nullable: 1

=head2 media

  data_type: 'text'
  is_nullable: 1

=head2 reply_to

  data_type: 'integer'
  is_nullable: 1

=head2 fwd_from

  data_type: 'bigint'
  is_nullable: 1

=head2 via_bot_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "uid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "id",
  { data_type => "integer", is_nullable => 1 },
  "from_id",
  { data_type => "bigint", is_nullable => 1 },
  "to_id",
  { data_type => "bigint", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "flags",
  { data_type => "integer", is_nullable => 1 },
  "date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "action",
  { data_type => "text", is_nullable => 1 },
  "media",
  { data_type => "text", is_nullable => 1 },
  "reply_to",
  { data_type => "integer", is_nullable => 1 },
  "fwd_from",
  { data_type => "bigint", is_nullable => 1 },
  "via_bot_id",
  { data_type => "bigint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</uid>

=back

=cut

__PACKAGE__->set_primary_key("uid");

=head1 UNIQUE CONSTRAINTS

=head2 C<msg_id>

=over 4

=item * L</id>

=item * L</from_id>

=item * L</to_id>

=back

=cut

__PACKAGE__->add_unique_constraint("msg_id", ["id", "from_id", "to_id"]);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-02-02 16:43:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nSQqyQDMInjnT0t6izqGmw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
