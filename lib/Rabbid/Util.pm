package Rabbid::Util;
use Mojo::Base -strict;
use Mojo::Collection 'c';
use POSIX 'ceil';

# Split long paragraphs in short snippets
sub split_long_paragraph {
  my $full_p = shift;

  return $full_p if length($full_p) < 2000;

  my @lines = ();

  # The paragraph is still too long
  while (length($full_p) > 1200) {

    # Get the start
    my $clean_p = substr($full_p, 0, 1000, '');

    # Try to split at sentence positions
    if ($full_p =~ s/^(.{0,300}?[\?\!\.\:]["']?)\s+([A-ZÖÜÄ])/$2/) {
      push @lines, $clean_p . $1; # . '~~~';
    }

    # Try to split at comma
    elsif ($full_p =~ s/^(.{0,300}?,)\s+//) {
      push @lines, $clean_p . $1; # . '~~~';
    }

    # Try to split at space
    elsif ($full_p =~ s/^(.{0,300}?)\s+//) {
      push @lines, $clean_p . $1; # . '~~~';
    }

    # Well - who damn cares?!
    else {
      push @lines, $clean_p; # . '~~~';
    };
  };

  # There is a rest left
  push @lines, $full_p if $full_p;

  return c(@lines);
};

# Get total pages
sub total_pages {
  my ($total_results, $items_per_page) = @_;
  return 0 if $total_results <= 0;
  return ceil($total_results / ($items_per_page || 1));
};


1;
