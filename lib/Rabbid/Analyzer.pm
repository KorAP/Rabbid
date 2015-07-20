package Rabbid::Analyzer;
use strict;
use warnings;
use Search::Tokenizer;
use Lingua::Stem::UniNE::DE qw/stem_de/;

# Create tokenizer method for SQLite fts
sub tokenize {
  return Search::Tokenizer->new(
    # Words are word characters plus "'" and "-"
    regex =>  qr/\p{Word}+(?:[-']\p{Word}+)*/,

    # Simple stemming and seperator removal
    filter => sub {
      my $t = shift;
      if ($t =~ /[a-z0-9äöüßÖÜÄ]/i) {
	$t =~ y/-//ds;
	return stem_de $t;
      };

      # Ignore the word
      return;
    },

    # case folding
    lower => 1
  );
};


1;


__END__
