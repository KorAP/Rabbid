package Rabbid::Corpus;
use Rabbid::Document;
use Rabbid::Analyzer;
use Mojo::Base -base;
use Scalar::Util 'blessed';

has 'oro';
has 'schema';

# Add files to the database
# Accepts Rabbid::Document objects and file names
sub add {
  my $self = shift;
  return unless $self->oro;

  # Initialize database
  if ($self->oro->created &&
	!$self->{_initialized}) {
    $self->_initialize or return;
  };

  my @docs = @_;
  my $inserts = 0;

  # Start transaction
  $self->oro->txn(
    sub {
      my $oro = shift;

      # Iterate over all documents
      foreach my $doc (@docs) {

	# Make doc an object
	unless (blessed $doc) {
	  $doc = Rabbid::Document->new($doc) or return -1;
	};

	# Add meta information
	$oro->insert(Doc => $doc->meta) or return -1;

	my $para = 0;

	# Create casted doc id
	my $doc_id = 'CAST(' . $doc->meta('doc_id') . ' AS INTEGER)';

	foreach ($doc->snippet->each) {
	  my $content = $_->content;

	  $content .= '~~~' if $_->join;
	  $content .= '###' if $_->final;

	  # Paragraph position
	  my $para_pos = 'CAST(' . $para++ . ' AS INTEGER)';

	  # Insert Paragraph to database
	  $oro->insert(Text => {
	    in_doc_id => \$doc_id,
	    para => \$para_pos,
	    content => $content
	  }) or return -1;
	};

	# Insert succesful
	$inserts++;
      };
    }
  ) or return;

  return $inserts;
};


# Initialize Corpus database
sub _initialize {
  my $self = shift;
  my $schema = $self->schema;

  return $self->oro->txn(
    sub {
      my $oro = shift;

      my @keys = qw(title TEXT);
      foreach (keys %$schema) {
	push @keys, $_ . ' ' . $schema->{$_};
      };

      my $keys = join(',', @keys);

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
CREATE VIRTUAL TABLE IF NOT EXISTS Text USING fts4 (
 in_doc_id, para, content, tokenize=perl 'Rabbid::Analyzer::tokenize'
)
FTS

      # genre polDir domain year
      foreach (qw/doc_id /, keys %$schema) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Doc ($_)
SQL
      };
    }
  );
};

1;

__END__
