package Rabbid::Controller::Search;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::Util 'quote';
require Rabbid::Analyzer;

my $items = 20;

sub kwic {
  my $c = shift;
  my $q = $c->param('q');

  my $result = [];

  if ($q) {
    my $oro = $c->oro;

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

    # Search Fulltext
    $result = $oro->select(
      [
	Doc => [qw/author year title domain genre polDir file/] => { doc_id => 1 },
	Text => [
	  'content',
	  'in_doc_id',
	  'para',
	  [ $oro->offsets('Text') => 'offset' ]
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
    if ($result) {
      my ($intro, $job) = $oro->offsets->();
      my $flipflop = 'flip';
      my $last;

      foreach my $para (@$result) {
	my @snippet;

	# Give matches flip flop information
	if ($last && $last ne $para->{in_doc_id}) {
	  $flipflop = $flipflop eq 'flip' ? 'flop' : 'flip';
	};
	$para->{flipflop} = $flipflop;
	$last = $para->{in_doc_id};

	# Minor changes to the object
	_prep_para($para);

	# There are offsets defined - highlight!
	my @marks;
	if ($para->{offset}) {
	  my $text = $para->{content};

	  my $offset = ref $para->{offset} ? $para->{offset} :
	    $job->($para->{offset});

	  foreach (reverse @{$offset}) {
	    # TODO: Prepend and append '_' symbals with the numbers
	    # of offset characters before you mark everything in the substring.
	    # -> remove _ before showing.

	    if (length($text) >= ($_->[2] + $_->[3])) {
	      substr($text, $_->[2] + $_->[3], 0, '</mark>');
	      substr($text, $_->[2], 0, '<mark>');
	      push @marks, $_->[2], $_->[3];
	    };
	  };
	  delete $para->{offset};

	  $para->{marks} = \@marks;

	  # Extend to the left
	  my $left_context_start = '<span class="context-left">';
	  $left_context_start .= '<span class="extend left button"></span>' if $para->{previous};

	  # Extend to the right
	  my $right_context_end = '</span>';
	  $right_context_end = '<span class="extend right button"></span></span>'
	    if $para->{next};

	  # Prepare marks for match spans
	  unless ($text =~ s!^(.*?)(<mark>.+</mark>)(.*?)$!${left_context_start}$1</span><span class="match">$2</span><span class="context-right">$3${right_context_end}!o) {
	    $text = "${left_context_start}</span><span class=\"match\">" . $text . "</span><span class=\"context-right\">${right_context_end}";
	  };
	  $para->{content} = $text;
	};
      };
    };
  };

  return $c->render(
    template => 'search',
    kwic => $result,
  );
};


sub _prep_para {
  my $para = shift;

  # Last parameter in document
  unless ($para->{content} =~ s/###$//) {
    $para->{next} = $para->{para} + 1;
  };

  # No line break in para
  if ($para->{content} =~ s/~~~$//) {
    $para->{nobr} = 'nobr';
  };

  # There is a previous paragraph
  unless ($para->{para} == 0) {
    $para->{previous} = $para->{para} - 1;
  };
  return $para;
};


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

  return $c->render(json => _prep_para($match)) if $match;
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

