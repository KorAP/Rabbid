package Rabbid::Document;
use Scalar::Util qw/looks_like_number/;
use Data::Dumper;
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

  # Page numbers
  my $page  = 0;  # The current pagebreak number
  my @pages;      # Array of pages around the snippet

  # Parse document
  $dom->find('p')->each(
    sub {
      my $e = shift;

      my $nodes = $e->child_nodes;

      # Iterate over all child nodes of <p />
      my $text = '';
      my $first = 0;
      $nodes->each(
	sub {
	  my $el = shift;

	  if ($el->type eq 'tag') {

	    # There are pagebreaks defined
	    if ($el->tag eq 'br') {

	      # Reset the page number and add that to text
	      my $page_nr_markup = _set_page_number($el, \$page);

	      # The pagebreak is inside or at the end of
	      # the snippet
	      if ($text) {
		push @pages, $page;
	      }

	      # The pagebreak is at the beginning of the
	      # snippet
	      else {
		@pages = ($page);
	      };

	      $text .= $page_nr_markup;
	    }

	    # The paragraph has subspans
	    elsif ($el->tag eq 'span') {
	      if ($text) {

		# Flush snippet
		my $p = Rabbid::Document::Snippet->new(
		  $id++,
		  $text,
		);

		# First Subspan is not joined -
		# all others are
		$p->join(1) if $first++;

		# There are page numbers to remember
		if (@pages) {

		  # The first page around is the start
		  # page of the snippet
		  $p->start_page($pages[0]);

		  # The last page around is the end
		  # page of the snippet
		  $p->end_page($pages[-1]);

		  # Remember the last page only
		  @pages = ($pages[-1]);
		};

		push @snippet, $p;

		# Reset text
		$text = '';
	      };


	      # Treat subspans
	      $el->child_nodes->each(
		sub {
		  my $sub_span = shift;

		  # Subspan is a pagebreak
		  if ($sub_span->type eq 'tag' && $sub_span->tag eq 'br') {

		    # Reset the page number and add that to text
		    my $page_nr_markup = _set_page_number($sub_span, \$page);

		    # The pagebreak is inside or at the end of
		    # the snippet
		    if ($text) {
		      push @pages, $page;
		    }

		    # The pagebreak is at the beginning of the
		    # snippet
		    else {
		      @pages = ($page);
		    };

		    $text .= $page_nr_markup;
		  }

		  # Subspan contains text only
		  elsif ($sub_span->type eq 'text') {
		    $text .= $sub_span->content;
		  }
		}
	      );
	    };
	  }

	  # Add textual content to snippet
	  elsif ($el->type eq 'text') {
	    $text .= $el->content;
	  }
	});

      # Flush snippet
      if ($text) {

	# Flush snippet
	my $p = Rabbid::Document::Snippet->new(
	  $id++,
	  $text
	);
	$p->join(1) if $first++;

	# There are page numbers to remember
	if (@pages) {

	  # The first page around is the start
	  # page of the snippet
	  $p->start_page($pages[0]);

	  # The last page around is the end
	  # page of the snippet
	  $p->end_page($pages[-1]);

	  # Remember the last page only
	  @pages = ($pages[-1]);
	};

	push @snippet, $p;

	# Reset text
	$text = '';
      };
    });

  $snippet[-1]->final(1) if $snippet[-1];

  $meta{title} = $title;

  bless {
    meta => \%meta,
    snippet => c(@snippet)
  }, $class;
};

sub _set_page_number {
  my ($el, $page_ref) = @_;

  # Get the number of the following page
  my $nr = $el->attr('data-after');

  # Page number is not given or invalid
  if (!$nr || !looks_like_number($nr)) {
    $$page_ref++;
    warn 'Pagebreak is set but undefined -' .
      " autoincrement to $$page_ref";
  }

  # Set the page
  else {
    $$page_ref = $nr;
  };

  # Pagebreaks are surrounded by Whitespace
  # This will be trimmed again later
  return ' #.#PB=' . $$page_ref . '#.~ ';
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
  $_[0]->[0] = $_[1] if defined $_[1];
  $_[0]->[0];
};


# Textual content of the snippet
sub content {
  $_[0]->[1] = $_[1] if defined $_[1];
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

# The start page, if defined
sub start_page {
  $_[0]->[4] = $_[1] if defined $_[1];
  $_[0]->[4];
};

# The end page, if defined
sub end_page {
  $_[0]->[5] = $_[1] if defined $_[1];
  $_[0]->[5];
};

1;
