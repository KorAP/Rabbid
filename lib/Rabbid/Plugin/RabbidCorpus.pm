package Rabbid::Plugin::RabbidCorpus;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app) = @_;


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
