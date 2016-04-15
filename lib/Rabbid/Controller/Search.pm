package Rabbid::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util 'quote';
use Mojo::ByteStream 'b';
use Rabbid::Util;
require Rabbid::Analyzer;

my $items = 20;

sub _count {
  my $c = shift;

  my $q = $c->param('q');
  my $result;

  if ($q) {
    my $oro = $c->oro;

    # Set filtering
    if ($c->param('filterBy')) {

      # Search Fulltext
      $result = $oro->load(
	[
	  Doc => [qw/author year title domain genre polDir file/] => { doc_id => 1 },
	  Text => [
	    'count(para):para_count',
	    'count(distinct(in_doc_id)):doc_count'
	  ] => { in_doc_id => 1 }
	],
	{
	  content => {
	    match => quote($q)
	  },
	  -cache => {
	    chi => $c->chi,
	    expires_in => '120min'
	  },
	  scalar($c->param('filterBy')) => scalar($c->param('filterValue'))
	}
      );
    }
    else {

      # Search Fulltext
      $result = $oro->load(
	Text => [
	  'count(para):para_count',
	  'count(distinct(in_doc_id)):doc_count'
	],
	{
	  content => {
	    match => quote($q)
	  },
	  -cache => {
	    chi => $c->chi,
	    expires_in => '120min'
	  }
	}
      );
    };

    return (0,0) unless $result;
    return ($result->{para_count}, $result->{doc_count});
  };
  return (0,0);
};

sub kwic {
  my $c = shift;
  my $q = $c->param('q');

  my $result = [];

  if ($q) {
    my $oro = $c->oro;

    # Get count information per default
    # This should come from cache in morst of the cases
    my ($count, $doc_count) = $c->_count;
    $c->stash(totalResults => $count);
    $c->stash(totalDocs    => $doc_count);
    $c->stash(itemsPerPage => $items);
    $c->stash(totalPages   => Rabbid::Util::total_pages($count, $items));

    my %args = (
      -limit => $items
    );

    # Set paging
    if ($c->param('page')) {
      $args{-offset} = ($c->param('page') * $items) - $items,
    };

    # Set filtering
    if ($c->param('filterBy')) {
      $args{scalar $c->param('filterBy')} = scalar $c->param('filterValue');
    };

    # TODO: Use corpus-object for searching!

    # Search Fulltext
    $result = $oro->select(
      [
	Doc => [qw/author year title domain genre polDir file/] => { doc_id => 1 },
	Text => [
	  'content',
	  'in_doc_id',
	  'para',
	  'offsets(Text):marks'
	] => { in_doc_id => 1 }
      ],
      {
	content => {
	  match => quote($q)
	},
	-order => [qw/in_doc_id para/],
	-cache => {
	  chi => $c->chi,
	  expires_in => '30min'
	},
	%args
      }
    );

    # Prepare results
    if ($result && scalar @$result) {

      # Post process stored snippets
      # TODO: This should be realised in an outer join instead!
      # BEGIN
      my @or_condition;
      foreach (@$result) {
	push(@or_condition, {
	  in_doc_id => $_->{in_doc_id},
	  para => $_->{para}
	});
      };

      # Load stored snippets
      my $stored = $oro->select(
	[
	  Snippet => [qw/in_doc_id para left_ext right_ext marks/] => {
	    in_coll_id => 1
	  },
	  Collection => [qw/coll_id/] => {
	    coll_id => 1
	  }
	] => {
	  q => $q,
	  user_id => $c->rabbid_acct->id,
	  -or => \@or_condition
	}
      );

      my %marked;
      foreach (@$stored) {
	$marked{ $_->{in_doc_id} . '-' . $_->{para} } = $_;
      };
      foreach my $r (@$result) {
	if (my $stored = $marked{$r->{in_doc_id} . '-' . $r->{para}}) {
	  $r->{marked} = 'marked';
	  $r->{left_ext}  = $stored->{left_ext};
	  $r->{right_ext} = $stored->{right_ext};
	};
      };
      # END

      $c->extend_result($result);
      $c->prepare_result($result);
    };
  }
  else {
    $result = [];
  };

  return $c->render(
    template => 'search',
    kwic => $result,
  );
};


# Get snippet
sub snippet {
  my $c = shift;
  my $oro = $c->oro;
  my $para = 'CAST(' . $c->stash('para') . ' AS INTEGER)';
  my $doc_id = 'CAST(' . $c->stash('doc_id') . ' AS INTEGER)';
  my $match = $oro->load(
    Text => ['content', 'in_doc_id', 'para'] => {
      in_doc_id => \$doc_id,
      para => \$para
    }
  );


  if ($match) {
    $match->{content} = b($match->{content})->decode;
    return $c->render(
      json => $c->prepare_paragraph($match)
    );
  };

  return $c->reply->not_found;
};


1;


__END__

# This action will render a template
sub search {
  my $self = shift;

  # Search
  # - Support single words
  # - Support boolean search
  # - Support word sequences
  # - Support "Zusammenbrüche" for the word "Zusammenbruch"

  # Response:
  # - Should have all KWICs (grouped in docs)

  # KWIC
  # - One click (show doc info)
  # - Widen context (pre and post)
  # - show external HTML doc

  # Filter
  # - Textsorte/Domäne/Jahr/Politische Ausrichtung
  # - Year (von ... bis)
  # - may be combined

  # Render template "example/welcome.html.ep" with message
  # $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
};

sub doc {
  # The external HTML document
  # - highlight search
  # - show the requested highlight first
  # - Link to RTF
};



__END__

    # Search Fulltext
    $result = $oro->select(
      [
	Doc => [qw/author year title domain genre polDir file/] => { doc_id => 1 },
	Text => [
	  'content',
	  'in_doc_id',
	  'para',
	  'offsets(Text):marks'
	] => { in_doc_id => 1 }
      ],
      {
	content => {
	  match => quote($q)
	},
	-order => [qw/in_doc_id para/],
	-cache => {
	  chi => $c->chi,
	  expires_in => '30min'
	},
	%args
      }
    );


# SELECT Doc.author AS `author`, Doc.year AS `year`, Doc.title AS `title`, Doc.domain AS `domain`, Doc.genre AS `genre`, Doc.polDir AS `poldir`, Doc.file AS `file`, Text.content AS `content`, Text.in_doc_id AS `in_doc_id`, Text.para AS `para`, offsets(Text.Text) AS `marks` FROM Doc, Text WHERE Doc.doc_id = Text.in_doc_id AND Text.content MATCH ? ORDER BY in_doc_id, para LIMIT ? -- From Cache1 at lib/Rabbid/Controller/Search.pm line 56, <DATA> line 260.

    my $q = $c->param('q');
    my ($rv, $sth) = $oro->prep_and_exec(<<'SQL', [quote($q), $q, $c->rabbid_acct->id, $items],'cached');
SELECT
  Doc.author AS `author`,
  Doc.year AS `year`,
  Doc.title AS `title`,
  Doc.domain AS `domain`,
  Doc.genre AS `genre`,
  Doc.polDir AS `poldir`,
  Doc.file AS `file`,
  Text.content AS `content`,
  Text.in_doc_id AS `in_doc_id`,
  Text.para AS `para`,
  offsets(Text.Text) AS `marks`,
  Snippet.left_ext AS `leftExt`,
  Snippet.right_ext AS `rightExt`,
  Snippet.marks AS `marked`
FROM
  Text,
  Collection,
  User,
  Snippet
  LEFT OUTER JOIN
  Doc
ON
  Snippet.in_doc_id = Doc.doc_id
  AND
  Snippet.para = Text.para
  AND
  Snippet.in_coll_id = Collection.coll_id
WHERE
  Doc.doc_id = Text.in_doc_id
  AND
  Text.content MATCH ?
  AND
  Collection.q = ?
  AND
  Collection.user_id = ?
ORDER BY
  in_doc_id, para LIMIT ?
SQL
    if ($rv) {
      $result = [];
      while (my $row = $sth->fetchrow_hashref) {
	push(@$result, $row);
      };
    };
