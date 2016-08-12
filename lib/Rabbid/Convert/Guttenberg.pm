package Rabbid::Convert::Guttenberg;
use Mojo::Base 'Rabbid::Convert::Base';
use Mojo::ByteStream 'b';
use Mojo::Collection 'c';
use Mojo::Log;
use Rabbid::Util;
use File::Spec::Functions qw/catdir catfile splitpath/;

sub convert {
	my $self = shift;
  my $cb = ref $_[0] eq 'CODE' ? shift : undef;

	my $doc_id = $self->{id_offset} // 1;

  my $text = b($self->{input})->slurp;

  my ($end, $content) = (0, 0);
  my $meta = { doc_id => $doc_id };
  my ($prologue, $epilogue, @lines) = ('', '');

  # Split lines of text
  _to_lines($text)->each(
    sub {
      if ($_ =~ m!^\*\*\*\s*(?:START|END)!) {
				unless ($content) {
          $content = 1;
				}
				else {
					$end = 1;
				}
      }

      # Add to epilogue
      elsif ($end) {
        if ($_ =~ m!will be found in: (https?://[^\s]+)(?:\s*|$)!) {
          $meta->{url} = $1;
        }
        else {
          $epilogue .= $_ . "\n";
        };
      }

      # analyze prologue
      elsif (!$content) {

        # Add title
        if ($_ =~ s/^Title:\s+//) {
          $meta->{title} = $_;
        }

        # Add author to meta data
        elsif ($_ =~ s/^Author:\s+//) {
          $meta->{author} = $_;
        }

        # Add prologue comment
        else {
          $prologue .= $_ . "\n";
        };
      }

      # Push to lines
      else {
				push @lines, $_;
      };
    }
  );

	# Create new file
  my ($volume, $dirs, $filename) = splitpath($self->{input});
  $filename =~ s/\.txt$//;
  $filename .= '.rabbidml';

	my $new_file = catfile($self->{output}, $filename);

  my $log = $self->{log} // Mojo::Log->new;

	# Check if file can be opened
	if (open(FILE, '>', $new_file)) {

    # Add prologue
    $meta->{comment} = $prologue;
    $prologue = $self->get_prologue($meta);

    # Something is wrong with the meta data
    unless ($prologue) {
      close FILE;
      return;
    };

		print FILE $prologue;

    _to_paragraph(c(@lines))->each(
			sub {
        if ($_ =~ /(?:(?:produced|prepared) by|proofreading|Project Gutenberg)/i) {
          $epilogue .= $_ . "\n";
          return;
        };
				print FILE $_, "\n";
			}
		);

		print FILE $self->get_epilogue($epilogue);

    close FILE;

    $log->debug("File $new_file converted");

    if ($cb) {
      $cb->($new_file, $doc_id);
      return;
    };

    return [$new_file, $doc_id];
  }
  else {
    $log->warn('Unable to open ' . $new_file);
    return;
  };
};


# Parse lines
sub _to_lines {
  my $text = shift;
  $text->xml_escape
    ->split(
      '[\s\t]*\n+[\s\t]*\n+[\s\t]*'
    )->map(
      sub {
				my $t = shift;
				$t =~ s![\n\s\t]+! !gs;
				$t =~ s![\n\s\t]+$!!;
				$t;
      }
    );
};


# Convert to paragraphs
sub _to_paragraph {
  return $_[0]->map(
		sub {
			my $lines = Rabbid::Util::split_long_paragraph($_);
			return $lines unless ref $lines eq 'Mojo::Collection'; # Not splitted
			return '<span>' . $lines->join("</span>\n<span>") . '</span>'; # splitted
		}
	)->map(
		sub {
			'<p>' . $_ . '</p>';
		}
	);
};


1;
__END__
