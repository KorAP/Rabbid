package Rabbid::Analyzer;
use strict;
use warnings;
use Search::Tokenizer;
use Lingua::Stem::UniNE::DE qw/stem_de/;

# Create tokenizer method for SQLite fts
sub tokenize {
  return Search::Tokenizer->new(
    regex =>  qr/\p{Word}+(?:[-']\p{Word}+)*/,
    # qr/(\p{Word}+(?:[-]\p{Word}+)?|\s+|[^\w])/,
    filter => sub {
      my $t = shift;
      if ($t =~ /[a-z0-9äöüßÖÜÄ]/i) {
	$t =~ y/-//ds;
	return stem_de $t;
      };
      return;
    },
    lower => 1
  );
};


1;
