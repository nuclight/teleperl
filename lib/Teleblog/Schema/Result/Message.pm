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

=cut

__PACKAGE__->add_columns(
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
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-31 14:34:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4tloH6V4nwX9cyoc9yzAGg


__PACKAGE__->add_unique_constraint(msg_id => [ qw/id from_id to_id/ ]);
1;
