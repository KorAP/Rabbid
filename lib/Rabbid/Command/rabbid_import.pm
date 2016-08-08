package Rabbid::Command::rabbid_import;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw/quote/;

use Getopt::Long qw/GetOptionsFromArray :config no_auto_abbrev no_ignore_case/;

has description => 'Import RabbidML files';
has usage       => sub { shift->extract_usage };

# Run import command
sub run {
  my ($self, @args) = @_;

  GetOptionsFromArray(
    \@args,
    'f|file=s' => \my $file,
    'd|dir=s' => \my $dir,
    'c|corpus=s'  => \(my $corpus = 'default')
  );

  print $self->usage and return unless ($dir || $file);

  my $app = $self->app;

  if ($file) {
    if ($app->rabbid_import($corpus => $file)) {
      print 'Import ' . quote($file) . qq!.\n!;
    }
    else {
      $app->log->warn('Unable to import ' . quote($file));
    };
  };

  if ($dir) {
    my @files;
    if (opendir(DIR, $dir)) {
      @files = map { $dir . '/' . $_ } readdir(DIR);
      closedir(DIR);
    }
    else {
      $app->log->warn('Unable to open directory ' . quote($dir));
      return;
    };

    foreach $file (grep { -f } @files) {
      if ($app->rabbid_import($corpus => $file)) {
	print 'Import ' . quote($file) . qq!.\n!;
      }
      else {
	$app->log->warn('Unable to import ' . quote($file));
      };
    };
  };

  print "Done.\n\n";
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
    The corpus handle as defined in the configuration

  --file|f
    A file to import

  --dir|d
    A directory to import from

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