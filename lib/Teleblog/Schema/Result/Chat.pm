use utf8;
package Teleblog::Schema::Result::Chat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Teleblog::Schema::Result::Chat

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<chats>

=cut

__PACKAGE__->table("chats");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 title

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "title",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-31 12:16:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2VZe5wbf0HylQHqLTeXvKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
