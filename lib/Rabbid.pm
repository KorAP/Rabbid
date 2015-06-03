package Rabbid;
use Mojo::Base 'Mojolicious';
use Mojo::ByteStream 'b';
use Lingua::Stem::UniNE::DE qw/stem_de/;
use Cache::FastMmap;
require Rabbid::Analyzer;


our $VERSION = '0.1.0';

# 120 seconds inactivity allowed
$ENV{MOJO_INACTIVITY_TIMEOUT} = 120;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secrets(['jgfhnvfnhghGFHGfvnhrvtukrKHGUjhu6464cvrj764cc64ethzvf']);

  push @{$self->commands->namespaces}, __PACKAGE__ . '::Command';

  $self->types->type(rtf => 'application/rtf');

  $self->plugin(Notifications => {
    Alertify => 1
  });

  $self->defaults(
    title => 'Rabbid',
    description => 'Recherche- und Analyse-Basis für Belegstellen in Diskursen',
    layout => 'default'
  );

  $self->plugin('CHI' => {
    default => {
      driver     => 'FastMmap',
      root_dir   => $self->home . '/cache',
      cache_size => '20m'
    }
  });

  # Export collections
  $self->plugin('ReplyTable');

  my $user_db = $self->home .'/db/user.sqlite';
  $self->plugin(Oro => {
    default => {
      file => $self->home .'/db/rabbid.sqlite',
      attached => {
	coll => $self->home . '/db/collection.sqlite',
	user => $user_db
      }
    },
    user => {
      file => $user_db
    }
  });


  $self->plugin('Oro::Account' => {
    oro_handle => 'user',
    invalid => [qw/collection search overview corpus doc/],
    default_lang => 'de'
  });


  $self->plugin('TagHelpers::Pagination' => {
    separator => '',
    ellipsis => '<span class="ellipsis">...</span>',
    current => '<span class="current">[{current}]</span>',
    page => '<span class="page-nr">{page}</span>',
    next => '<span>&gt;</span>',
    prev => '<span>&lt;</span>'
  });


  $self->plugin('Oro::Viewer' => {
    default_count => 25,
    max_count => 100
  });


  $self->helper(
    hidden_parameters => sub {
      my $c = shift;
      my %param = @_;
      my (%with, %without);
      if ($param{with}) {
	$with{$_} = 1 foreach @{$param{with}};
      };
      if ($param{without}) {
	$without{$_} = 1 foreach @{$param{without}};
      };
      my $tag = '';
      foreach (@{ $c->req->params->names }) {
	if ((!$param{with} && !$without{$_}) || $with{$_}) {
	  $tag .= $c->hidden_field($_ => scalar $c->param($_)) . "\n";
	};
      };
      return b $tag;
    }
  );


  $self->helper(
    filter_by => sub {
      my $c = shift;
      my ($key, $value) = @_;
      return $c->link_to(
	$value,
	$c->url_with->query([
	  startPage => 1,
	  filterBy => $key,
	  filterOp => 'equals',
	  filterValue => $value
	])
      );
    }
  );


  $self->helper(
    extend_result => sub {
      my $c = shift;
      my $result = shift;

      foreach my $r (@$result) {

	# Store extension paragraphs
	my @para = ();

	# Get left extensions
	if ($r->{left_ext}) {
	  foreach (1 .. $r->{left_ext}) {
	    push (@para, $r->{para} - $_);
	  };
	  $r->{left} = [];
	};

	# Get right extensions
	if ($r->{right_ext}) {
	  foreach (1 .. $r->{right_ext}) {
	    push (@para, $r->{para} + $_);

	  };
	  $r->{right} = [];
	};

	# There are extensions
	next unless @para;

	# my $para = 'CAST(' . $c->stash('para') . ' AS INTEGER)';
	my $doc_id = 'CAST(' . $r->{in_doc_id} . ' AS INTEGER)';

	@para = map { +{ para => \"CAST($_ AS INTEGER)" } } @para;

	# Retrieve extended paragraphs
	my $para = $c->oro->select(
	  Text =>
	    [qw/para content in_doc_id/] => {
	      in_doc_id => \$doc_id,
	      -or => \@para,
	      -order => ['para']
	    });

	# Append left and right
	foreach (@$para) {

	  # This is part of the left context
	  if ($_->{para} < $r->{para}) {
	    $c->prepare_paragraph($_);
	    push(@{$r->{left}}, $_->{content});
	    delete $r->{previous} unless $_->{previous};
	  }

	  # This is part of the right context
	  else {
	    $c->prepare_paragraph($_);
	    push(@{$r->{right}}, $_->{content});
	    $r->{next} = $_->{next} > $r->{next} ? $_->{next} : $r->{next};
	  };
	};
      };
    }
  );


  # Create highlights, mark document flips, integrate extensions
  $self->helper(
    prepare_result => sub {
      my $c = shift;
      my $result = shift;

      my ($intro, $job) = $c->oro->offsets->();
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
	$c->prepare_paragraph($para);

	# There are offsets defined - highlight!
	my @marks;
	if ($para->{marks}) {
	  my $text = $para->{content};

	  my $marks = $para->{marks};
	  my $offset = ref $para->{marks} ? $para->{marks} :
	    $job->($para->{marks});

	  foreach (reverse @{$offset}) {
	    # TODO: Prepend and append '_' symbals with the numbers
	    # of offset characters before you mark everything in the substring.
	    # -> remove _ before showing.

	    if (length($text) >= ($_->[2] + $_->[3])) {
	      substr($text, $_->[2] + $_->[3], 0, '</mark>');
	      substr($text, $_->[2], 0, '<mark>');
	    };
	  };

	  $para->{marks} = $marks;

	  # Extend to the left
	  my $left = '<span class="context-left">';
	  if ($para->{previous}) {
	    $left .= '<span class="extend left button"></span>';
	  };
	  if ($para->{left}) {
	    $left .= '<span class="collapse left button"></span>';
	    foreach (@{$para->{left}}) {
	      $left .= '<span class="ext">' . $_ . '</span>';
	    };
	  };

	  # Extend to the right
	  my $right = '';
	  if ($para->{right}) {
	    foreach (@{$para->{right}}) {
	      $right .= '<span class="ext">' . $_ . '</span>';
	    };
	    $right .= '<span class="collapse right button"></span>';
	  };
	  if ($para->{next}) {
	    $right .= '<span class="extend right button"></span></span>';
	  }
	  else {
	    $right .= '</span>'
	  };

	  # Prepare marks for match spans
	  unless ($text =~ s!^(.*?)(<mark>.+</mark>)(.*?)$!${left}$1</span><span class="match">$2</span><span class="context-right">$3${right}!o) {
	    $text = "${left}</span><span class=\"match\">" .
	      $text .
		"</span><span class=\"context-right\">${right}";
	  };
	  $para->{content} = $text;
	};
      };
    }
  );

  $self->helper(
    prepare_paragraph => sub {
      my $para = pop;

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
    }
  );

  $self->helper(
    stem => sub { return stem_de pop }
  );

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->any('/login')->acct('login' => { return_url => 'collections'});
  $r->any('/login/forgotten')->acct('forgotten');
  $r->any('/about')->to(
    cb => sub {
      shift->render(template => 'impressum', about => 1)
    })->name('about');

  # Restricted routes
  my $res = $r->route('/')->over(allowed_for => '@all');
  $res->any('/login/remove')->acct('remove');
  $res->any('/preferences')->acct('preferences');
  $res->any('/logout')->acct('logout');

  $res->get( '/')->to('Collection#index', collection => 1)->name('collections');
  $res->get( '/collection/:coll_id')->to('Collection#collection', collection => 1)->name('collection');
  $res->get( '/search')->to('Search#kwic', search => 1)->name('search');
  $res->get( '/corpus')->to('Document#overview', overview => 1)->name('corpus');
  $res->get( '/corpus/raw/:file')->name('file');

  # Ajax ...
  $res->get( '/corpus/:doc_id/:para', [doc_id => qr/\d+/, para => qr/\d+/])->to('Search#snippet')->name('snippet');
  $res->post('/corpus/:doc_id/:para',[doc_id => qr/\d+/, para => qr/\d+/])->to('Collection#store');


  $r->any('/*catchall', { catchall => '' })->to(
    cb => sub {
      my $c = shift;
      return $c->redirect_to('acct_login') unless $c->allowed_for('@all');
      return $c->reply->not_found;
    });
};

1;
