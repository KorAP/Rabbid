package Rabbid::Corpus;
use Rabbid::Document;
use Rabbid::Analyzer;
use Mojo::Base -base;
use Mojo::ByteStream 'b';
use Data::Dumper;
use Scalar::Util 'blessed';
use Mojo::Log;

has 'log';
has 'oro';
has 'chi';
has 'schema';

# Add files to the database
# Accepts Rabbid::Document objects and file names
sub add {
  my $self = shift;

  return unless $self->oro;

  my @docs = @_;
  my $inserts = 0;

  # Start transaction
  unless ($self->oro->txn(
    sub {
      my $oro = shift;

      # Iterate over all documents
      foreach my $doc (@docs) {

				# Make doc an object
				unless (blessed $doc) {
					$doc = Rabbid::Document->new($doc) or return -1;
				};

				# Add meta information
				$oro->insert(
          Doc => $doc->meta($self->fields)
        ) or return -1;

				my $para = 0;

				# Create casted doc id
				my $doc_id = 'CAST(' . $doc->meta('doc_id') . ' AS INTEGER)';

				foreach ($doc->snippet->each) {
					my $content = $_->content;

					# Some special flag markers
					$content .= ' '; # Whitespace for the tokenizer
					if ($_->start_page || $_->end_page) {
						$content .= '~#' . ($_->start_page // 0) . '|' . ($_->end_page // 0) . '#~';
					};

					$content .= '~~~' if $_->join;
					$content .= '###' if $_->final;

					# Paragraph position
					my $para_pos = 'CAST(' . $para++ . ' AS INTEGER)';

					# Insert Paragraph to database
					$oro->insert(Text => {
						in_doc_id => \$doc_id,
						para      => \$para_pos,
						content   => $content
					}) or return -1;
				};

				# Insert succesful
				$inserts++;
      };
      return 1;
    }
  )) {
    $self->log->error('Document ID not unique or database not initialized') if $self->log;
    return;
  };

  # Clean associated cache
  $self->chi->clear;

  return $inserts;
};


# Return the schema array as [[name, value], [name, value]]
# with a parameter
# or - without a parameter as [name, name, name]
# Todo: Maybe schema should be more like the first one ...
sub fields {
  my $self = shift;
  my $schema = $self->schema;
  my @fields = ();

  if (@_) {
    for (my $i = 0; $i < @$schema; $i+=2) {
      push @fields, [ $schema->[$i] => $schema->[$i+1]];
    };
  }
  else {
    for (my $i = 0; $i < @$schema; $i+=2) {
      push @fields, $schema->[$i];
    };
  };
  return \@fields;
};


sub snippet {
  my $self = shift;
  my ($doc_id, $para) = @_;

  return unless $self->oro;

  # Cast parameters
  $doc_id = 'CAST(' . $doc_id . ' AS INTEGER)';
  $para   = 'CAST(' . $para   . ' AS INTEGER)';

  # Get match
  my $match = $self->oro->load(
    Text => ['content', 'in_doc_id', 'para'] => {
      in_doc_id => \$doc_id,
      para => \$para
    }
  ) or return;

  return $match;
};


sub _column_type {
  my $type = uc($_->[1]);

  if ($type eq 'DATE') {
    $type = 'INTEGER';
  };
  return $type;
};

# Initialize Corpus database
sub init {
  my $self = shift;

  return 1 if $self->{_initialized};

  $self->oro->txn(
    sub {
      my $oro = shift;

      my $keys = join(
        ', ',
        map { $_->[0] . ' ' . _column_type($_->[1]) } @{$self->fields(1)}
      );

      # Create document table
      $oro->do(<<"SQL") or return -1;
CREATE TABLE IF NOT EXISTS Doc (
  doc_id  INTEGER PRIMARY KEY,
  $keys
)
SQL

      # Create paragraph table
      # local_id is numerical to ensure the next/previous paragraph can be retrieved.
      # use with: SELECT * FROM Paragraph WHERE content MATCH '"der Aufbruch"';
      $oro->do(<<'FTS') or return -1;
CREATE VIRTUAL TABLE Text USING fts4 (
  in_doc_id, para, content, tokenize=perl 'Rabbid::Analyzer::tokenize'
)
FTS

      # genre polDir domain year
      foreach (qw/doc_id /, @{$self->fields}) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Doc ($_)
SQL
      };
    }
  ) or return;

  $self->{_initialized} = 1;
  return 1;
};

1;

__END__



