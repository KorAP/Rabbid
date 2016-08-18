package Rabbid::Command::rabbid_import;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Loader qw/load_class/;
use Mojo::Util qw/quote/;
use File::Temp qw/tempfile tempdir/;

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;

has description => 'Import RabbidML files';
has usage       => sub { shift->extract_usage };

# Run import command
sub run {
  my ($self, @args) = @_;

  my @files;
  GetOptionsFromArray(
    \@args,
    'f|file=s'   => \@files,
    'd|dir=s'    => \my $dir,
    'c|corpus=s' => \(my $corpus = 'default'),
    'x|conversion=s' => \(my $conversion_class),
    'id|id_offset=i' => \(my $id_offset = 1)
  );

  print $self->usage and return unless ($dir || @files);

  my $app = $self->app;
  my $level = $app->log->level;

  my $errors = 0;

  # Grrep files from directory
  if ($dir) {
    my @dirfiles;
    if (opendir(DIR, $dir)) {
      @dirfiles = map { $dir . '/' . $_ } readdir(DIR);
      closedir(DIR);
    }
    else {
      $app->log->error('Unable to open directory ' . quote($dir));
      $errors++;
    };
    push @files, @dirfiles;
  };

  # Convert and import files
  if ($conversion_class) {
    my @rabbid_files = ();

    # Load conversion class
    $conversion_class = 'Rabbid::Convert::' . $conversion_class;
    if (load_class($conversion_class)) {
      warn 'Unable to load conversion class ' . $conversion_class;
      return;
    };

    # Create temporary directory
    my $temp_out = tempdir;

    # Configure converter
    foreach (grep { -f } @files) {
      my $converter = $conversion_class->new(
        input     => $_,
        output    => $temp_out,
        log       => $app->log,
        id_offset => $id_offset
      );

      # Run conversion
      $converter->convert(
        sub {
          my ($file, $id) = @_;
          my $name = quote($file);

          print "Convert $name\n";
          if ($app->rabbid->import($corpus => $file)) {
            print "Import $name\n";
            $id_offset = $id;
          }
          else {
            print "Unable to import $name\n";
            $errors++;
          };
        }
      );
    };
  }

  # Import RabbidML files
  else {

    foreach (grep { -f } @files) {
      if ($app->rabbid->import($corpus => $_)) {
        print 'Import ' . quote($_) . qq!\n!;
      }
      else {
        print 'Unable to import ' . quote($_) . "\n";
        $errors++;
      };
    };
  };

  print "Failed imports: $errors\n" if $errors;
  print "Done.\n\n";

  $app->log->level('error');
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Rabbid::Command::rabbid_import - Import RabbidML files

=head1 SYNOPSIS

  usage: perl script/rabbid rabbid_import -c corpus -f file

  Import RabbidML (simple HTML files) into
  Rabbid database.

  Expects the following parameters

  --corpus|c
    The corpus handle as defined in the configuration.

  --file|f
    A file to import. Can be defined multiple times.

  --dir|d
    A directory to import from.

  --id_offset|-id
    ID offset, defaults to 1. Only used in conjunction with the x flag.

=head DESCRIPTION

L<Rabbid::Command::rabbid_import> helps
to import RabbidML files to the Rabbid database.

=head1 ATTRIBUTES

L<Rabbid::Command::rabbid_import> inherits all attributes
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
