package Rabbid::Command::rabbid_import;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Import RabbidML files.';
has usage       => sub { shift->extract_usage };



__END__

=pod

=head1 SYNOPSIS

  $ perl script/rabbid rabbid_import
