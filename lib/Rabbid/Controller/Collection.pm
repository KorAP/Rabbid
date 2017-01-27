package Rabbid::Controller::Collection;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/quote unquote encode/;
use Mojo::ByteStream 'b';
use Rabbid::Util;
use RTF::Writer;
require Rabbid::Analyzer;

my $items = 20;


# View all collections
sub index {
  my $c = shift;

  # Get user id
  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;

  # Get collection object
  my $coll = $c->rabbid->collection(user_id => $user_id) or return $c->reply->not_found;

  # Show all collections
  return $c->render(
    template   => 'collections',
    collection => $coll->list_all
  );
};


# View one collection
sub collection {
  my $c = shift;
  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;
  my $coll_id = $c->stash('coll_id');

  # Gett collection
  my $coll = $c->rabbid->collection(
    user_id => $user_id,
    id => $coll_id
  ) or return $c->reply->not_found;

  # Get query string
  my $query = $coll->query;

  # Use validator
  my $offset = (($c->param('startPage') * $items) - $items) if $c->param('startPage');

  # Set paging
  my $result = $coll->load(
    limit => $items,
    offset => $offset
  );

  $c->stash(totalResults => $coll->snippet_count);
  $c->stash(itemsPerPage => $items);
  $c->stash(totalPages => Rabbid::Util::total_pages($coll->snippet_count, $items));

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

  # Check for user_id
  my $user_id = $c->rabbid_acct->id or return $c->reply->not_found;

  # Get user provided data
  my $json = $c->req->json;

  # No query submitted
  return $c->reply->not_found unless $json->{q};

  # Create collection object
  my $coll = $c->rabbid->collection(
    user_id => $user_id
  );

  # Set query
  $coll->query($json->{q});

  my $doc_id = $c->stash('doc_id');
  my $para   = $c->stash('para');

  # Collection constrained:
  $coll->store(
    doc_id    => $doc_id,
    para      => $para,
    leftExt   => $json->{leftExt},
    rightExt  => $json->{rightExt},
    marks     => $json->{marks}
  ) or return $c->reply->not_found;

  # Create response json
  my %response = (
    msg     => 'stored',
    doc_id  => $doc_id,
    coll_id => $coll->id,
    para    => $para
  );

  # Add further response parameter
  foreach (qw/leftExt rightExt marks/) {
    $response{$_} = $json->{$_} if exists $json->{$_};
  };

  # Everything is stored
  return $c->render(json => \%response);
};


# Export to excel
sub _export_to_excel {
  my ($c, $query, $result) = @_;

  # Header data
  # TODO: Use corpus schema
  # qw/author title year domain genre polDir file page/
  my @header = @{$c->rabbid->corpus->fields};

  # Initialize table
  my @table = ['snippet', @header];

  # Prepare table with results
  foreach my $res (@$result) {
    my $content = $res->{content};
    $content =~ s!\<mark\>(.*?)\<\/mark\>![$1]!g; # Make markup less HTMLy

    # Remove multiple whitespaces
    $content =~ s!\s\s+! !g;

    # Remove markup
    $content =~ s!\<\/?span[^>]*?\>!!g;

    my @row = ($content);

    if ($res->{start_page_ext}) {
      $res->{page} = $res->{start_page_ext};
      if ($res->{start_page_ext} != $res->{end_page_ext}) {
        $res->{page} .= '-' . $res->{end_page_ext};
      };
    };

    # Append further values to table
    push(@row, $res->{$_} // undef) foreach @header;

    # Append row to table
    push @table, \@row;
  };

  # Give the file a name
  $c->res->headers->content_disposition(
    'inline; filename="Belegstellen-' . unquote($query) . '.xlsx"'
  );

  return $c->reply->table(xlsx => \@table);
};


# Todo: use Mojo::Template!
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

    # Remove multiple whitespaces
    $content =~ s!\s\s+! !g;

    # Remove markup
    $content =~ s!\<\/?span[^>]*?\>!!g;

    # Transform markup
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

    # TODO: Make this schema agnostic
    my @meta = ();
    push (@meta, $res->{author}. ': ') if $res->{author};
    if ($res->{title}) {
      push (@meta, \'{\b', $res->{title} . ' ', \'}');
    };
    push (@meta, '(' . $res->{year}. ') ')  if $res->{year};

    my $fields = $c->rabbid->corpus->fields;

    foreach (grep { $_ !~ /^author|title|year$/ } @$fields) {
      push (@meta, $res->{$_} . ', ')     if $res->{$_};
    };

    $meta[-1] =~ s/,\s+$/ /;

    if ($res->{start_page_ext}) {
      push @meta, '(S. ' . $res->{start_page_ext} . '-' . $res->{end_page_ext} . ')';
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
};


1;
