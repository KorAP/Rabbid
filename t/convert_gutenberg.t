use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::DOM;
use utf8;
use Mojo::Util qw/slurp encode/;
use lib '../lib', 'lib';
use File::Temp qw/tempfile tempdir/;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

use_ok('Rabbid::Convert::Gutenberg');

my $temp_out = tempdir(CLEANUP => 1);

my $file = catfile(dirname(__FILE__), 'data', 'pg5323.txt');
my $c = Rabbid::Convert::Gutenberg->new(
  input => $file,
  output => $temp_out,
  id_offset => 5
);

my @files = $c->convert;

is(scalar @files, 1, 'One document converted');

ok(-e $files[0]->[0], 'One document loadable');

my $dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]->[0]);

ok($dom, 'File is parsed');

is($dom->at('title')->text, 'Effi Briest');

ok($dom->at('meta[name=doc_id][content=5]'), 'Element exists');

is($dom->at('meta[name=url]')->attr('content'), encode('utf-8', "http://www.gutenberg.org/5/3/2/5323/"), 'Element exists');


is($dom->find('p')->[2]->text, encode('UTF-8', 'Erstes Kapitel'), 'Text');
like($dom->find('p')->[4]->at('span')->text, qr/Herrenhauses/, 'Text');
is($dom->find('p')->[7]->text, encode('UTF-8', '»Möchtest du\'s?«'), 'Text');

my $node = $dom->at('body')->next_node;
while ($node && $node->type ne 'comment') {
  $node = $node->next_node;
};

unlike($node->content, qr/--/, 'Comment node');
like($node->content, qr!&#151;!, 'Comment node');


$file = catfile(dirname(__FILE__), 'data', 'pg4601-short.txt');
$c = Rabbid::Convert::Gutenberg->new(
  input => $file,
  output => $temp_out,
  id_offset => 6
);

@files = $c->convert;

$dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]->[0]);

is($dom->at('head title')->text, 'Papa Hamlet', 'Title');
is($dom->at('head meta[name=author]')->attr('content'), 'Arno Holz and Johannes Schlaf', 'Author');

is($dom->find('body p')->[0]->text, 'PAPA HAMLET', 'First paragraph');

like($dom->find('body p')->[-1]->text, qr/^Lirumn, Larum!/, 'Last paragraph');


$file = catfile(dirname(__FILE__), 'data', 'pg29376-short.txt');
$c = Rabbid::Convert::Gutenberg->new(
  input => $file,
  output => $temp_out,
  id_offset => 7
);

@files = $c->convert;

$dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]->[0]);

is($dom->at('head title')->text, encode('UTF-8', 'Bahnwärter Thiel'), 'Title');
is($dom->at('head meta[name=author]')->attr('content'), 'Gerhart Hauptmann', 'Author');

like($dom->find('body p')->[0]->text, qr!Anmerkungen!, 'First paragraph');

is($dom->find('body p')->[-1]->text, ']', 'Last paragraph');

done_testing;
__END__
