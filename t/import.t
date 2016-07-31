use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use CHI;
use utf8;
use Data::Dumper;
use lib '../lib', 'lib';
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

use DBIx::Oro;
my $file = catfile(dirname(__FILE__), 'data', 'text1.html'),

use_ok('Rabbid::Corpus');

# Default schema
#  author  TEXT,
#  year    INTEGER,
#  domain  TEXT,
#  genre   TEXT,
#  polDir  TEXT,
#  file    TEXT

ok(my $corpus = Rabbid::Corpus->new(
  oro => DBIx::Oro->new,
  chi => CHI->new( driver => 'Memory', global => 1 ),
  schema => {
    year   => 'INTEGER',
    author => 'TEXT',
    title => 'TEXT'
  }
), 'New Import');

ok($corpus->oro, 'Oro is initialized');

ok($corpus->init, 'Initialize corpus');

ok($corpus->add($file), 'Added document');

my $text = $corpus->oro->select('Text');
is($text->[0]->{in_doc_id}, 1, 'doc id');
is($text->[0]->{content}, 'Dies ist ein Beispieltext. ', 'content');
is($text->[0]->{para}, 0, 'Paragraph');

is($text->[1]->{in_doc_id}, 1, 'doc id');
is($text->[1]->{content},
   'Er soll lediglich illustrieren, wie Rabbid funktioniert. ', 'content');
is($text->[1]->{para}, 1, 'Paragraph');

is($text->[2]->{in_doc_id}, 1, 'doc id');
is($text->[2]->{content},
   'Nichts weiter. ~~~', 'content');
is($text->[2]->{para}, 2, 'Paragraph');

is($text->[4]->{in_doc_id}, 1, 'doc id');
is($text->[4]->{content},
   'Tschüß! ###', 'content');
is($text->[4]->{para}, 4, 'Paragraph');

$text = $corpus->oro->load('Doc');

is($text->{doc_id}, 1, 'Doc id');
is($text->{author}, 'Max Mustermann', 'Autor');
is($text->{title}, 'Example 1', 'Title');
is($text->{year}, 1919, 'Year');

done_testing;
