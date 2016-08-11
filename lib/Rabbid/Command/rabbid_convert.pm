package Rabbid::Command::rabbid_convert;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Loader qw/load_class/;
use Mojo::Util qw/quote/;
use File::Temp qw/tempfile tempdir/;

use Rabbid::Convert::I5;

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;

has description => 'Convert documents to RabbidML files';
has usage       => sub { shift->extract_usage };

# Run import command
sub run {
  my ($self, @args) = @_;

  GetOptionsFromArray(
    \@args,
    'f|file=s' => \my $file,
    'o|output=s' => \my $output,
    'x|conversion=s' => \(my $conversion_class = 'I5'),
    'id|id_offset=i' => \(my $id_offset = 1)
  );

  # Todo: Do not use temporary file
  $output //= tempdir;

  print $self->usage and return unless $file;

  my $app = $self->app;

  $conversion_class = 'Rabbid::Convert::' . $conversion_class;

  if (load_class($conversion_class)) {
    warn 'Unable to load conversion class ' . $conversion_class;
    return;
  };

  # Configure converter
  my $converter = $conversion_class->new(
    input => $file,
    output => $output,
    log => $app->log,
    id_offset => $id_offset
  );

  # Run conversion
  $converter->convert(
    sub {
      my $file = shift;
      print "Convert $file\n";
    }
  );
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

Rabbid::Command::rabbid_convert - Convert documents to RabbidML files

=head1 SYNOPSIS

  usage: perl script/rabbid rabbid_convert -f file -o directory

  Convert files to RabbidML.

  Expects the following parameters

  --file|-f
    A file to import

  --output|-o
    A directory to convert to

  --conversion|-x
    The source format, defaults to I5

  --id_offset|-id
    ID offset, defaults to 1


=head DESCRIPTION

L<Rabbid::Command::rabbid_convert> helps
to convert documents to RabbidML. Currently supported formats are
C<I5> and C<Guttenberg>.

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
