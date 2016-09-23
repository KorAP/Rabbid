package Rabbid::Collection;
use Mojo::Base -base;
use Mojo::Collection 'c';
use Mojo::ByteStream 'b';

has 'oro';
has 'id';
has 'user_id';
has 'corpus';

# TODO: Merge count and query to one single call

# List all collections the user has
sub list_all {
  my $self = shift;

  # Retrieve all collections from the user
  my $colls = $self->oro->select(
    [
      Collection => [qw/q coll_id:id/] => {
        coll_id => 1
      },
      Snippet => ['count(rowid):samples'] => {
        in_coll_id => 1
      }
    ] => {
      user_id => $self->user_id,
      -order_by => [qw/-last_modified/],
      -group_by => ['id']
    });

  # Found collections
  if ($colls) {
    $colls = c(@$colls)->map(
      sub {
        $_->{q} = b($_->{q})->decode;
        $_;
      });
    return $colls;
  };

  return;
};


# Count the snippets
sub query {
  my $self = shift;

  if (@_) {
    $self->{_query} = shift;
    return;
  };

  # Snippets were already count
  return $self->{_query} if $self->{_query};

  return unless $self->id;

  # This is only to ensure the user has this collection
  my $q = $self->oro->load(Collection => [qw/q/] => {
    coll_id => $self->id,
    user_id => $self->user_id
  }) or return undef;

  $self->{_query} = b($q->{q})->decode;

  return $self->{_query};
};

# Count the snippets
sub snippet_count {
  my $self = shift;

  return 0 unless $self->id;

  # Only retrieve if not cached
  $self->{_count} = $self->oro->count(
    Snippet => {
      in_coll_id => $self->id
    }
  ) unless $self->{_count};

  return $self->{_count}
};


# Load a specific collection
# TODO: Use filtering!
sub load {
  my $self = shift;
  my %param = @_;

  my $oro = $self->oro or return;

  # Get collection based on id

  my %args = ();

  foreach (qw/limit offset/) {
    $args{'-' . $_} = $param{$_} if exists $param{$_};
  };

  my $fields = $self->corpus->fields;

  # Retrieve all snippets
  my $result = $self->oro->select(
    [
      Doc => $fields => {
        doc_id => 1
      },
      Snippet => [qw/left_ext right_ext marks/] => {
        in_doc_id => 1,
        para => 2
      },
      Text => [qw/content in_doc_id para/] => {
        in_doc_id => 1,
        para => 2
      }
    ] => {
      in_coll_id => $self->id,
      -order => [qw/in_doc_id para/],
      %args
    });

  return $result;
};


# Store snippet
sub store {
  my $self = shift;
  my %param = @_;

  # Create constraint
  my $constraint = {
    user_id => $self->user_id,
    q       => $self->query
  };

  # Start transaction
  # Merge and retrieve collection
  $self->oro->txn(
    sub {
      my $oro = shift;

      # No id passed
      unless ($self->id) {

        # Get collection id based on query
        if ($self->query) {

          # Upsert collection
          $oro->merge(
            Collection => {
              last_modified => \"datetime('now')"
            } => $constraint
          );

          # Load collection based on constraint
          my $collection = $oro->load(Collection => ['coll_id'] => $constraint);

          unless ($collection) {
            warn 'Unable to create collection';
            return -1;
          };

          # Set collection id
          $self->id($collection->{coll_id});
        }

        # Error
        else {
          warn 'Neither id nor query given';
          return -1;
        };
      };

      # TODO: Check if leftExt and rightExt are numbers
      if ($oro->merge(
        Snippet => {
          left_ext  => $param{leftExt}  // 0,
          right_ext => $param{rightExt} // 0,
          marks     => $param{marks}    // undef
        },
        {
          in_doc_id  => $param{doc_id},
          in_coll_id => $self->id,
          para       => $param{para}
        }
      )) {
        # Everything is fine
        return 1;
      };

      # Something failed - role back
      return -1;
    }
  ) or return;

  return 1;
};


# Initialize collection database
# This should be in Rabbid::Collection
sub init {
  my $self = shift;
  return 1 if $self->{_initialized};

  my $oro = $self->oro;

  $oro->txn(
    sub {
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
  ) or return;

  $self->{_initialized} = 1;
  return 1;
};

1;
