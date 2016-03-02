package Rabbid::Command::rabbid_init;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw/quote/;

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;

has description => 'Initialize Rabbid';
has usage       => sub { shift->extract_usage };

# Run init command
sub run {
  my ($self, @args) = @_;

  my $app = $self->app;

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

  # Release init hook
  $app->rabbid_init;

  print "Done.\n\n";
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

Rabbid::Command::rabbid_init - Initialize Rabbid

=head1 SYNOPSIS

  usage: perl script/rabbid rabbid_init

=head DESCRIPTION

L<Rabbid::Command::rabbid_init> will initialize
the Rabbid databases.

=head1 ATTRIBUTES

L<Rabbid::Command::rabbid_init> inherits all attributes
from L<Mojolicious::Command> and implements the following new ones.


=head2 description

  my $description = $cmd->description;
  $cmd = $cmd->description('Foo!');

Short description of this command, used for the command list.


=head2 usage

  my $usage = $cmd->usage;
  $cmd = $cmd->usage('Foo!');

Usage information for this command, used for the help screen.


=head1 METHODS

L<Rabbid::Command::rabbid_import> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.


=head2 run

  $cmd->run;

Run this command.

=cut
