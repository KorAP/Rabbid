package Rabbid::Plugin::RabbidCorpus;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app) = @_;

  # On rabbid init
  $app->hook(
    on_rabbid_init => sub {
      # Get corpus definitions from configuration
      my $corpora = $app->config('Corpora');

      # No configuration found
      unless ($corpora) {
	$app->log->warn('Please define corpora in configuration file');
	return;
      };

      foreach (keys %$corpora) {
	my $rabbid_corpus = $app->rabbid_corpus($_) or next;
	$rabbid_corpus->init;
      }
    }
  );

  # TODO: Collect corpora in a meaningful way
  $app->helper(
    rabbid_corpus => sub {
      my $c = shift;

      # Get corpus definitions from configuration
      my $corpora = $c->config('Corpora');

      # No configuration found
      unless ($corpora) {
	$c->app->log->warn('Please define corpora in configuration file');
	return;
      };

      my $corpus = shift;

      # No configuration for corpus found
      unless ($corpus = $corpora->{$corpus}) {
	$c->app->log->warn('Corpus not defined');
	return;
      };

      # Get schema
      my $schema = $corpus->{schema};

      # No schema for corpus found
      unless ($schema) {
	$c->app->log->warn('Corpus has no schema');
	return;
      };

      # Create new corpus object
      my $rabbid_corpus = Rabbid::Corpus->new(
	oro    => $c->oro($corpus->{oro_handle} // 'default'),
	chi    => $c->chi($corpus->{chi_handle} // 'default'),
	schema => $schema
      );

      # Error
      unless ($rabbid_corpus) {
	$c->app->log->warn(q!Rabbid::Corpus can't be created!);
	return;
      };

      return $rabbid_corpus;
    }
  );

  $app->helper(
    rabbid_import => sub {
      my $c = shift;

      my $rabbid_corpus = $c->rabbid_corpus(shift) or return;

      # Add files to corpus
      foreach (@_) {
	$rabbid_corpus->add($_) or return;
      };

      return 1;
    }
  );
};


1;


__END__


sub _init_corpus_db {
  my $oro = shift;

  $oro->txn(
    sub {
      # Create document table
      $oro->do(<<'SQL') or return -1;
CREATE TABLE Doc (
  doc_id  INTEGER PRIMARY KEY,
  author  TEXT,
  year    INTEGER,
  title   TEXT,
  domain  TEXT,
  genre   TEXT,
  polDir  TEXT,
  file    TEXT
)
SQL

      # Create paragraph table
      # local_id is numerical to ensure the next/previous paragraph can be retrieved.
      # use with: SELECT * FROM Paragraph WHERE content MATCH '"der Aufbruch"';
      $oro->do(<<'FTS') or return -1;
CREATE VIRTUAL TABLE IF NOT EXISTS Text USING fts4 (
 in_doc_id, para, content, tokenize=perl 'Rabbid::Analyzer::tokenize'
)
FTS

      foreach (qw/doc_id genre polDir domain year/) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Doc ($_)
SQL
      }
    }
  ) or return;

  return 1;
};
