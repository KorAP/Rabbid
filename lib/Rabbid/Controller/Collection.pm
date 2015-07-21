package Rabbid::Controller::Collection;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/quote unquote/;
use Mojo::ByteStream 'b';
use RTF::Writer;
require Rabbid::Analyzer;


# View all collections
sub index {
  my $c = shift;

  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;

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
  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;

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
  if ($c->param('format')) {
    if ($c->param('format') eq 'xlsx') {
      return $c->_export_to_excel($query => $result);
    }
    elsif ($c->param('format') eq 'rtf') {
      return $c->_export_to_rtf($query => $result);
    };
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
  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;

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
      my $oro = shift;

      # Merge and retrieve collection
      $oro->merge(
	Collection => {
	  last_modified => \"datetime('now')"
	} => $constraint
      );

      # $c->notify(warn => 'Hui: ' . $oro->last_sql . $c->dumper($oro->select('Collection')));

      # Gett collection id
      my $coll_id = $oro->load(Collection => $constraint);

      if ($coll_id) {
	$coll_id = $coll_id->{coll_id};
      }
      else {
	$c->notify(error => 'Unable to create collection');
	return -1;
      };

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

sub _export_to_rtf {
  my ($c, $query, $result) = @_;
  my $scalar;

  my $rtf = RTF::Writer->new_to_string(\$scalar);

  # Create RTF Prolog
  $rtf->prolog(
    title => 'Belegstellen-' . $query,
    author => $c->rabbid_acct->handle,
    operator => 'Rabbid',
    charset => 'utf8'
  );

  $rtf->paragraph(\'\fs40\b', "Belegstellen für " . quote($query), \'\sb400');

  my $i = 1;

  # Iterate over results
  foreach my $res (@$result) {
    my $content = $res->{content};
    $content =~ s!\<\/?span[^>]*?\>!!g; # Remove markup

    $content = b($content)->split(qr/(<\/?mark>)/)->map(
      sub {
	if ($_ eq '<mark>') {
	  return \'{\b\ul';
	} elsif ($_ eq '</mark>') {
	  return \'}';
	};
	return $_;
      });

    # Write content
    $rtf->paragraph(\'\brdrb \brdrs\brdrw10\brsp20 {\fs4\~}');
    $rtf->paragraph(\'\sb100');
    $rtf->paragraph(\'\li500\qj', \'{\b', $i++, \')} ', $content->to_array);

    my @meta = ();
    push (@meta, $res->{author}. ': ') if $res->{author};
    if ($res->{title}) {
      push (@meta, \'{\b', $res->{title} . ' ', \'}');
    };
    push (@meta, '(' . $res->{year}. ') ')  if $res->{year};
    push (@meta, $res->{domain} . ', ')     if $res->{domain};
    push (@meta, $res->{genre} . ', ')      if $res->{genre};
    push (@meta, $res->{polDir} . ', ')     if $res->{polDir};

    if ($res->{domain} || $res->{genre} || $res->{polDir}) {
      chop $meta[-1];
      chop $meta[-1];
    };

    # Todo:
    # {\field{\*\fldinst{HYPERLINK "http://www.suck.com/"}}{\fldrslt{\ul stuff }}}

    $rtf->paragraph(\'\sb200\i', @meta);
    $rtf->paragraph('[ ' . $res->{file} . ']') if $res->{file};

    # Write new line
    # $rtf->paragraph(\'\brdrb \brdrs\brdrw10\brsp20 {\fs4\~}');
    $rtf->paragraph(\'\sb100');
  };

  # Add page numbers
  $rtf->number_pages($query . ': ');

  $rtf->close;

  # https://metacpan.org/module/Mojolicious::Plugin::RenderFile
  return $c->render_file(
    data => $scalar,
    format => 'rtf',
    filename => 'Belegstellen-' . unquote($query) . '.rtf',
    content_disposition => 'inline'
  );


  # Give the file a name
  # $c->res->headers->content_disposition(
  #   'inline; filename="Belegstellen-' . unquote($query) . '.rtf"'
  # );

};



1;
