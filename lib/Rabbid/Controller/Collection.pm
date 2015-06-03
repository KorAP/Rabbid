package Rabbid::Controller::Collection;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/quote unquote/;
require Rabbid::Analyzer;

# View all collections
sub index {
  my $c = shift;

  my $user_id = $c->acct->id or return $c->reply->not_found;

  # Retrieve all collections from the user
  my $colls = $c->oro->select(
    [
      Collection => [qw/q coll_id:id/] => {
	coll_id => 1
      },
      Snippet => ['count(rowid):samples'] => {
	in_coll_id => 1
      }
    ] => {
      user_id => $user_id,
      -order_by => [qw/-last_modified/],
      -group_by => ['id']
    });

  # Show all collections
  return $c->render(
    template   => 'collections',
    collection => $colls
  );
};


# View one collection
sub collection {
  my $c = shift;
  my $coll_id = $c->stash('coll_id');

  my $oro = $c->oro;
  my $user_id = $c->acct->id or return $c->reply->not_found;

  # Get collection based on id
  my $coll = $oro->load(Collection => [qw/q/] => {
    coll_id => $coll_id,
    user_id => $user_id
  });

  # Not found the collection
  return $c->reply->not_found unless $coll;

  # Get query from collection
  my $query = $coll->{q};

  # Retrieve all snippets
  my $result = $oro->select(
    [
      Doc => [qw/author year title domain genre polDir file/] => {
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
      in_coll_id => $coll_id,
      -order => [qw/in_doc_id para/]
    });

  $c->extend_result($result);
  $c->prepare_result($result);

  # Export collection in Excel format
  if ($c->param('format') && $c->param('format') eq 'xlsx') {
    return $c->_export_to_excel($query => $result)
  };

  # Override query
  $c->param(q => $query);

  # Render to browser
  return $c->render(
    template => 'search',
    q        => $query,
    kwic     => $result
  );
};


# Store snippet in collection
sub store {
  my $c = shift;

  # Get user provided data
  my $doc_id  = $c->stash('doc_id');
  my $para    = $c->stash('para');
  my $json    = $c->req->json;
  my $user_id = $c->acct->id or return $c->reply->not_found;

  # No query submitted
  return $c->reply->not_found unless $json->{q};

  my $oro = $c->oro;

  # Collection constrained:
  my $constraint = {
    user_id => $user_id,
    q       => $json->{q}
  };

  my $coll_id;

  # Start transaction
  $oro->txn(
    sub {

      # Merge and retrieve collection
      $oro->merge(
	Collection => {
	  last_modified => \"datetime('now')"
	} => $constraint
      );

      # Gett collection id
      $coll_id = $oro->load(Collection => $constraint)->{coll_id};

      # Todo: Check if leftExt and rightExt are numbers
      if ($oro->merge(
	Snippet => {
	  left_ext  => $json->{leftExt}  // 0,
	  right_ext => $json->{rightExt} // 0,
	  marks     => $json->{marks}    // undef
	},
	{
	  in_doc_id  => $doc_id,
	  in_coll_id => $coll_id,
	  para       => $para
	}
      )) {
	# Everything is fine
	return 1;
      };

      # Something failed - role back
      return -1;
    }
  ) or return $c->reply->not_found;

  # Create response json
  my %response = (
    msg     => 'stored',
    doc_id  => $doc_id,
    coll_id => $coll_id,
    para    => $para
  );

  # Add further response parameter
  foreach (qw/leftExt rightExt marks/) {
    $response{$_} = $json->{$_} if exists $json->{$_};
  };

  # Everything is stored - party!!
  return $c->render(json => \%response);
};


# Export to excel
sub _export_to_excel {
  my ($c, $query, $result) = @_;

  # Header data
  my @header = qw/author title year domain genre polDir file/;

  # Initialize table
  my @table = ['snippet', @header];

  # Prepare table with results
  foreach my $res (@$result) {
    my $content = $res->{content};
    $content =~ s!\<mark\>(.*?)\<\/mark\>![$1]!g; # Make markup less HTMLy
    $content =~ s!\<\/?span[^>]*?\>!!g; # Remove markup
    my @row = ($content);

    # Append further values to table
    push(@row, $res->{$_}) foreach @header;

    # Append row to table
    push @table, \@row;
  };

  # Give the file a name
  $c->res->headers->content_disposition(
    'inline; filename="Belegstellen-' . unquote($query) . '.xlsx"'
  );

  return $c->reply->table(xlsx => \@table);
};

1;
