package Rabbid::Plugin::RabbidHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Mojo::Util qw/xml_escape encode decode/;
use Mojo::JSON qw/true false/;
use DBIx::Oro;
use Lingua::Stem::UniNE::DE qw/stem_de/;
use Rabbid::Corpus;
use Rabbid::Collection;
require Rabbid::Analyzer;

# Todo: Support final mark

sub _field_convert {
  my ($value, $type) = @_;

  return $value unless $type;

  if (uc($type) eq 'DATE') {
    if ($value =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/) {
      my $date = '';
      $date .= $3 . '.' if $3 ne '00';
      $date .= $2 . '.' if $2 ne '00';
      $date .= $1 if $1;
      $date =~ s/0(\d)\./$1\./g;
      return $date;
    };
  };
  return $value;
};


# Register plugin to establish helpers
sub register {
  my ($plugin, $app) = @_;

  # Initialize rabbid databases
  $app->helper(
    'rabbid.init' => sub {
      $app->plugins->emit_hook('on_rabbid_init');
    }
  );

  $app->hook(
    on_rabbid_init => sub {
      my $rabbid_collection = $app->rabbid->collection;
      unless ($rabbid_collection->init) {
				$app->log->error('Unable to initialize collection database');
      };
    }
  );

  $app->helper(
    'rabbid.collection' => sub {
      my $c = shift;
      my $corpus = $c->rabbid->corpus;
      return Rabbid::Collection->new(
        oro => $c->oro($app->oro('coll')) // $app->oro,
        corpus => $corpus,
        @_
      );
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
  # TODO: Check security implications!
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
      my ($key, $value, $type) = @_;
      return '' unless $value;

      $value = b($value)->decode;
      return $c->link_to(
				_field_convert($value, $type),
				$c->url_with->query([
					startPage   => 1,
					filterBy    => $key,
					filterOp    => 'equals',
					filterValue => $value
				])
      );
    }
  );

  # Extend the results based on the retrieved snippets
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
						push(@{$r->{left}}, $_); # b($_->{content})->decode);
					}

					# This is part of the right context
					else {
						$c->prepare_paragraph($_);
						push(@{$r->{right}}, $_); # b($_->{content})->decode);
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
						};
					};

					$text = xml_escape b($text)->decode;
					$text =~ s/#!#/</g;
					$text =~ s/#!~/>/g;

					$para->{marks} = $marks;

					# Extend to the left
					my $left = '<span class="context-left">';

          if ($para->{start_page}) {
            $para->{start_page_ext} = $para->{start_page};
            $para->{end_page_ext} = $para->{end_page};
          };

          if ($para->{left}) {
            my $first = $para->{left}->[0];
            $para->{start_page_ext} = $first->{start_page} if $first->{start_page};

            foreach (@{$para->{left}}) {
							$left .= '<span class="ext';
							$left .= ' nobr' if $_->{nobr};
							$left .= '"';
							$left .= ' data-start-page="' . $_->{start_page} . '"' if $_->{start_page};
							$left .= '>' . xml_escape(b($_->{content})->decode) . '</span>';
						};
					};

					# Extend to the right
					my $right = '';
					if ($para->{right}) {
            my $last = $para->{right}->[-1];
            $para->{end_page_ext} = $last->{end_page} if $last->{end_page};

						foreach (@{$para->{right}}) {
							$right .= '<span class="ext';
							$right .= ' nobr' if $_->{nobr};
							$right .= '"';
							$right .= ' data-end-page="' . $_->{end_page} . '"' if $_->{end_page};
							$right .= '>' . xml_escape(b($_->{content})->decode) . '</span>';
						};
					};

					$right .= '</span>';

					# Prepare marks for match spans
					unless ($text =~ s!^(.*?)(<mark>.+</mark>)(.*?)$!
            ${left}$1</span><span class="match">$2</span>
            <span class="context-right">$3${right}!ox) {
						$text = "${left}</span>".
              "<span class=\"match\">${text}</span>".
              "<span class=\"context-right\">${right}";
					};
					$para->{content} = $text;
					$c->convert_pagebreaks_html($para);
				};
      };
    }
  );

  # Todo: This is rather a snippet preparation
  $app->helper(
    prepare_paragraph => sub {
      my $para = pop;

      # Last parameter in document
      if ($para->{content} =~ s/###$//) {
				$para->{final} = Mojo::JSON->true;
      };

      # No line break in para
      if ($para->{content} =~ s/~~~$//) {
				$para->{nobr} = 'nobr';
      };

      # Has a page number
      if ($para->{content} =~ s/~#(\d+)\|(\d+)#~$//) {
				$para->{start_page} = $1 + 0;
				$para->{end_page} = $2 + 0;
      };

      # Remove the final whitespace, added for the tokenizer
      $para->{content} =~ s/\s$//;
      return $para;
    }
  );

  $app->helper(
    convert_pagebreaks_html => sub {
      my $para = pop;
      $para->{content} =~ s! #\.#PB=(\d+?)#\.~ !<span class="pb" data-after="$1"></span>!g;
      return $para;
    }
  );

  # Used in Search
	$app->helper(
    convert_pagebreaks_json => sub {
      my $para = pop;
      $para->{content} =~ s! #\.#PB=(\d+?)#\.~ !\[\[PB=$1\]\]!g;
      return $para;
    }
  );
};


1;


__END__
