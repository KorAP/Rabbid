package Rabbid::Plugin::RabbidCorpus;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/quote/;

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

      my $corpus_name = shift;
      my $corpus;

      # No configuration for corpus found
      unless ($corpus = $corpora->{$corpus_name}) {
        $c->app->log->error('Corpus ' . quote($corpus_name // '???') . ' not defined');
        return;
      };

      # Get schema
      my $schema = $corpus->{schema};

      # No schema for corpus found
      unless ($schema) {
        $c->app->log->error('Corpus ' . quote($corpus_name) . ' has no schema');
        return;
      };

      # Create new corpus object
      my $rabbid_corpus = Rabbid::Corpus->new(
        oro    => $c->oro($corpus->{oro_handle} // 'default'),
        chi    => $c->chi($corpus->{chi_handle} // 'default'),
        schema => $schema,
        log    => $c->app->log
      );

      # Error
      unless ($rabbid_corpus) {
        $c->app->log->error(q!Rabbid::Corpus can't be created!);
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
        my $inserts = $rabbid_corpus->add($_) or return;
        $c->app->log->info('Imported ' . $_);
      };

      return 1;
    }
  );
};


1;


__END__
