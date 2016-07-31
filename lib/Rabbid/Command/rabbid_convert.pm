package Rabbid::Command::rabbid_convert;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw/quote/;
use Rabbid::Convert::I5;

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;

has description => 'Convert files to RabbidML';
has usage       => sub { shift->extract_usage };

# Run import command
sub run {
  my ($self, @args) = @_;

  GetOptionsFromArray(
    \@args,
    'f|file=s' => \my $file,
    'o|output=s' => \my $output
  );

  print $self->usage and return unless ($file || $output);

  my $app = $self->app;

  # Configure converter
  my $i5 = Rabbid::Convert::I5->new(
    input => $file,
    output => $output,
    log => $app->log
    # Support id_offset!
  );

  # Run conversion
  $i5->convert(
    sub {
      my $file = shift;
      print "Converted $file\n";
    }
  );
};

1;

__END__


1;

__END__

=pod

=encoding utf8

=head1 NAME

Rabbid::Command::rabbid_convert - Convert to RabbidML files

=head1 SYNOPSIS

  usage: perl script/rabbid rabbid_convert -f file -o directory

  Convert (exclusively for the moment) I5 files to RabbidML.

  Expects the following parameters

  --file|f
    A file to import

  --output|o
    A directory to convert to

=head DESCRIPTION

L<Rabbid::Command::rabbid_convert> helps
to convert docuemnts to RabbidML.

=head1 ATTRIBUTES

L<Rabbid::Command::rabbid_convert> inherits all attributes
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

L<Rabbid::Command::rabbid_convert> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.


=head2 run

  $cmd->run;

Run this command.

=cut
