package Rabbid::Document;
use Mojo::DOM;
use Mojo::Base -strict;
use Mojo::ByteStream 'b';
use Mojo::Collection 'c';

# Constructor
sub new {
  my $class = shift;
  my $file = shift;
  return unless -f $file;

  my $data = b($file)->slurp;
  return unless $data;

  my $dom = Mojo::DOM->new(xml => 1)->parse($data->decode);

  # Get title
  my $title = $dom->at('title')->all_text //
    $dom->at('body h1')->all_text;

  # Parse meta data
  my %meta;
  $dom->at('head')->find('meta[name][content]')->each(
    sub {
      my $e = shift;
      $meta{$e->attr('name')} = $e->attr('content');
    }
  );

  # Make every snippet identifiable
  my $id = 1;
  my @snippet = ();

  # Parse document
  $dom->find('p')->each(
    sub {
      my $e = shift;

      # There are subspans
      my $spans = $e->find('span');

      if ($spans->size) {

	# First Subspan is not joined - all others are
	my $first = 0;
	$spans->each(
	  sub {
	    my $el = shift;
	    my $text = $el->all_text or return;
	    my $p = Rabbid::Document::Snippet->new(
	      $id++,
	      $text
	    );
	    $p->join(1) if $first++;
	    push @snippet, $p;
	  });
      }

      # There are no subspans
      else {
	my $text = $e->all_text or return;
	my $p = Rabbid::Document::Snippet->new(
	  $id++,
	  $text
	);
	push @snippet, $p;
      }
    });

  $snippet[-1]->final(1) if $snippet[-1];

  $meta{title} = $title;

  bless {
    meta => \%meta,
    snippet => c(@snippet)
  }, $class;
};


# Metadata field of the document
sub meta {
  my $self = shift;
  my $cat = shift;
  if ($cat) {
    return $self->{meta}->{$cat} // '';
  };
  return $self->{meta};
};


# Snippets of the document
sub snippet {
  my $self = shift;
  return $self->{snippet} unless defined $_[0];
  return $self->{snippet}->[$_[0]];
};


# Snippet class of documents
package Rabbid::Document::Snippet;
use Mojo::Base -strict;


# Constructor
sub new {
  my $class = shift;
  bless [@_], $class;
};


# Identifier
sub id {
  $_[0]->[0] = shift if defined $_[1];
  $_[0]->[0];
};


# Textual content of the snippet
sub content {
  $_[0]->[1] = shift if defined $_[1];
  $_[0]->[1];
};


# Is the snippet in the same paragraph as the
# previous snippet?
sub join {
  $_[0]->[2] = ($_[1] ? 1 : 0) if defined $_[1];
  $_[0]->[2] // 0;
};


# Is the snippet the final snippet of the document
sub final {
  $_[0]->[3] = ($_[1] ? 1 : 0) if defined $_[1];
  $_[0]->[3] // 0;
};

1;
