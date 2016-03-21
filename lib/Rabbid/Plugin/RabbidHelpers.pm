package Rabbid::Plugin::RabbidHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Mojo::Util qw/xml_escape encode decode/;
use DBIx::Oro;
use Lingua::Stem::UniNE::DE qw/stem_de/;
use Rabbid::Corpus;
require Rabbid::Analyzer;

# Register plugin to establish helpers
sub register {
  my ($plugin, $app) = @_;

  $app->hook(
    on_rabbid_init => sub {
      unless (_init_collection_db($app->oro('coll') // $app->oro)) {
	$app->log->error('Unable to initialize collection database');
      };
    }
  );

  # Initialize rabbid databases
  $app->helper(
    rabbid_init => sub {
      $app->plugins->emit_hook('on_rabbid_init');
    }
  );

  # Add links to navigation line
  my @navigation;
  $app->helper(
    rabbid_navi => sub {
      my $c = shift;
      my $b;

      # Just retrieve the navigation
      unless (@_) {
	foreach (@navigation) {

	  # Render string variables
	  unless (ref $_) {
	    $b .= $c->render_to_string($_);
	  }

	  # Append bytestreams
	  else {
	    $b .= $_;
	  }
	};
	return b($b) if $b;
	return '';
      };

      # Adding navigations can only happen in app mode
      if (ref $app ne 'Rabbid') {
	$app->log->warn(
	  'rabbid_navi(x) needs to be called by app'
	);
	return;
      };

      push(@navigation, @_);
    }
  );


  # Move query parameters to hidden form fields
  $app->helper(
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

  # Create filtering links
  $app->helper(
    filter_by => sub {
      my $c = shift;
      my ($key, $value) = @_;
      return '' unless $value;
      return $c->link_to(
	$value,
	$c->url_with->query([
	  startPage   => 1,
	  filterBy    => $key,
	  filterOp    => 'equals',
	  filterValue => $value
	])
      );
    }
  );

  $app->helper(
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
	    if (!defined $r->{next} && defined $_->{next}) {
	      $r->{next} = $_->{next};
	    }
	    elsif (defined $_->{next}) {
	      $r->{next} = $_->{next} > $r->{next} ? $_->{next} : $r->{next};
	    };
	  };
	};
      };
    }
  );

  # Create highlights, mark document flips, integrate extensions
  $app->helper(
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

	  # SQLite FTS uses byte offsets instead of character offsets -
	  # so all range specific operations need byte prefix
	  foreach (reverse @{$offset}) {
	    # TODO: Prepend and append '_' symbols with the numbers
	    # of offset characters before you mark everything in the substring.
	    # -> remove _ before showing.
	    if (bytes::length($text) >= ($_->[2] + $_->[3])) {

	      # Set end and start marker of matches
	      bytes::substr($text, $_->[2] + $_->[3], 0, '#!#/mark#!~');
	      bytes::substr($text, $_->[2], 0, '#!#mark#!~');

	      # # This fixes a characters2byte bug
	      # # TODO: needs to be tested though!
	      # # Remove the string including the end
	      # my $remove = bytes::substr($text, $_->[2], $_->[3] + 10, '');
	      # # Add the marker
	      # bytes::substr($remove, $_->[3], 0, '#!#/mark#!~');
	      # bytes::substr($text, $_->[2], 0, $remove);
	      # bytes::substr($text, $_->[2], 0, '#!#mark#!~');
	    };
	  };

	  $text = xml_escape b($text)->decode;
	  $text =~ s/#!#/</g;
	  $text =~ s/#!~/>/g;

	  $para->{marks} = $marks;

	  # Extend to the left
	  my $left = '<span class="context-left">';
	  # if ($para->{previous}) {
	  $left .= '<span class="buttons">';
	  $left .= '<span class="extend left"></span>';
	  $left .= '<span class="collapse left"></span>';
	  $left .= '</span>';
	  # };
	  if ($para->{left}) {
	    # $left .= '<span class="collapse left button"></span>';
	    foreach (@{$para->{left}}) {
	      $left .= '<span class="ext">' . xml_escape($_) . '</span>';
	    };
	  };

	  # Extend to the right
	  my $right = '';
	  if ($para->{right}) {
	    foreach (@{$para->{right}}) {
	      $right .= '<span class="ext">' . xml_escape($_) . '</span>';
	    };
	    # $right .= '<span class="collapse right button"></span>';
	  };
	  # if ($para->{next}) {
	  $right .= '<span class="buttons">';
	  $right .= '<span class="collapse right"></span>';
	  $right .= '<span class="extend right"></span>';
	  $right .= '</span>';
	  #}
	  #else {
	    $right .= '</span>';
	  #};

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

  $app->helper(
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

  $app->helper(
    stem => sub { return stem_de pop }
  );
};


# Initialize collection database
sub _init_collection_db {
  my $oro = shift;

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

  return 1;
};



1;


__END__
