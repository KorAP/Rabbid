package Rabbid::Command::build_collection_db;
use Mojo::Base 'Mojolicious::Command';
use DBIx::Oro;

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Initialize Rabbid collection database (DEPRECATED)';
has usage       => sub { shift->extract_usage };

sub _init {
  my $db_file = shift;

  # Create database
  return DBIx::Oro->new(
    $db_file => sub {
      my $oro = shift;

      # Create collection table
      $oro->do(<<'SQL') or return -1;
CREATE TABLE Collection (
  coll_id       INTEGER PRIMARY KEY,
  user_id       INTEGER,
  last_modified INTEGER,
  q             TEXT
)
SQL

      # Indices on collection table
      foreach (qw/coll_id user_id q last_modified/) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Collection ($_)
SQL
      };
      $oro->do(<<"SQL") or return -1;
CREATE UNIQUE INDEX IF NOT EXISTS coll_i ON Collection (user_id, q)
SQL

      # Create snippet table
      $oro->do(<<'SQL') or return -1;
CREATE TABLE Snippet (
  in_coll_id INTEGER,
  in_doc_id  INTEGER,
  para       INTEGER,
  left_ext   INTEGER,
  right_ext  INTEGER,
  marks      TEXT
)
SQL

      # Indices on snippet table
      foreach (qw/in_doc_id in_coll_id para/) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Snippet ($_)
SQL
      };
      $oro->do(<<"SQL") or return -1;
CREATE UNIQUE INDEX IF NOT EXISTS all_i ON Snippet (in_doc_id, para, in_coll_id)
SQL
    }
  );
};

sub run {
  my $self = shift;

  local $|;
  $|++;

  my $app = $self->app;

  my $db_file    = shift || $app->home . '/db/collection.sqlite';

  unlink $db_file if -e $db_file;

  print "Init $db_file\n";

  _init($db_file);
  print "Okay.\n\n";
  return 1;
};


1;

__END__

=pod

=head1 SYNOPSIS

  $ perl script/rabbid build_collection_db
