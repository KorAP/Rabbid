package Rabbid::Controller::Collection;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;
  my $oro = $c->oro;
  my $found = $oro->select(
    [
      Collection => [qw/q/] => { coll_id => 1 },
      Snippet => ['count(rowid):samples'] => { in_coll_id => 1 }
    ] => {
      user_id => 1,
      -order_by => [qw/-last_modified/],
      -group_by => ['coll_id']
    });
  return $c->render(
    template => 'collection',
    collection => $found
  );
}

sub store {
  my $c = shift;
  my $doc_id = $c->stash('doc_id');
  my $para = $c->stash('para');
  my $json = $c->req->json;

  # No query submitted
  return $c->reply->not_found unless $json->{q};

  my $oro = $c->oro;

  # Collection constrained:
  my $constraint = {
    user_id => 1,
    q => $json->{q}
  };

  # Merge and retrieve collection
  my $coll_id;
  $oro->merge(
    Collection => {
      last_modified => \"datetime('now')"
    } => $constraint
  );
  $coll_id = $oro->load(Collection => $constraint)->{coll_id};

  # Todo: Check if leftExt and rightExt are numbers
  if ($oro->merge(
    Snippet => {
      left_ext  => $json->{leftExt} // 0,
      right_ext => $json->{rightExt} // 0,
      marks     => $json->{marks} // undef
    },
    {
      in_doc_id  => $doc_id,
      in_coll_id => $coll_id,
      para       => $para
    }
  )) {
    return $c->render(
      json => {
	str => $json->{marks} . '-' .
	  $json->{leftExt} . '-' .
	    $json->{rightExt} . ' - ' .
	      $json->{q}
	    });
  };
  return $c->render(text => $oro->last_sql);
};

1;
