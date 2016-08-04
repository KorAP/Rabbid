use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use utf8;
use lib '../lib', 'lib';
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

my $file = catfile(dirname(__FILE__), 'data', 'text1.html');

use_ok('Rabbid::Document');

ok(my $doc = Rabbid::Document->new($file), 'Load document');

is($doc->meta('doc_id'), 1, 'Document ID');
is($doc->meta('author'), 'Max Mustermann', 'Author');
is($doc->meta('year'), '1919', 'Year');
is($doc->meta('title'), 'Example 1', 'Title');

my $p = $doc->snippet(0);
is($p->content, 'Dies ist ein Beispieltext.', '1st snippet text');
ok(!($p->join), '1st snippet join');
ok(!($p->final), '1st snippet final');

$p = $doc->snippet(1);
is($p->content, 'Er soll lediglich illustrieren, wie Rabbid funktioniert.', '2nd snippet text');
ok(!($p->join), '2nd snippet join');
ok(!($p->final), '2nd snippet final');

$p = $doc->snippet(2);
is($p->content, 'Nichts weiter - öhrlich!', '3rd snippet text');
ok($p->join, '3rd snippet join');
ok(!($p->final), '3rd snippet final');

$p = $doc->snippet(4);
is($p->content, 'Tschüß!', '4th snippet text');
ok(!($p->join), '4th snippet join');
ok($p->final, '4th snippet final');

is_deeply($doc->meta, {
  doc_id => 1,
  author => 'Max Mustermann',
  year => 1919,
  title => 'Example 1'
}, 'Meta data');

ok($doc->snippet(1)->id != $doc->snippet(2)->id, 'Identifier change');


# Text with pagebreaks
$file = catfile(dirname(__FILE__), 'data', 'text3.html');

ok($doc = Rabbid::Document->new($file), 'Load document');

is($doc->meta('doc_id'), 3, 'Document ID');
is($doc->meta('author'), 'Theodor Fontane', 'Author');
is($doc->meta('year'), '1894', 'Year');
is($doc->meta('title'), 'Example 3', 'Title');

$p = $doc->snippet(0);
is($p->content, q/ #.#PB=1#.~  #.#PB=2#.~ »Liebe Effi! ... So fängt es nämlich immer an, und manchmal nennt er mich auch seine 'kleine Eva'.« #.#PB=3#.~ /, '1st snippet text');
ok(!($p->join), '1st snippet join');
ok(!($p->final), '1st snippet final');
is($p->start_page, 1, 'Start page is set');
is($p->end_page, 3, 'End page is set');

$p = $doc->snippet(1);
is($p->content, q/»Freilich ist das die Hauptsache, 'Weiber weiblich, Männer männlich' - das ist, wie ihr wißt, einer von Papas Lieblingssätzen. Und nun helft mir erst Ordnung schaffen auf dem Tisch hier, sonst gibt es wieder eine Strafpredigt.« #.#PB=4#.~ /, '2nd snippet text');
ok(!($p->join), '2nd snippet join');
ok(!($p->final), '2nd snippet final');
is($p->start_page, 3, 'Start page is set');
is($p->end_page, 4, 'End page is set');

$p = $doc->snippet(2);
is($p->content, q{»Ich bin... nun, ich bin für gleich und gleich und natürlich auch für Zärtlichkeit und Liebe. Und wenn es Zärtlichkeit und Liebe nicht sein können, weil Liebe, wie Papa sagt, doch nur ein Papperlapapp ist (was ich aber nicht glaube), nun, #.#PB=5#.~  dann bin ich für Reichtum und ein vornehmes Haus, ein ganz vornehmes, wo Prinz Friedrich Karl zur Jagd kommt, auf Elchwild oder Auerhahn, oder wo der alte Kaiser vorfährt und für jede Dame, auch für die jungen, ein gnädiges Wort hat. #.#PB=6#.~  #.#PB=7#.~ }, '3rd snippet text');
ok(!($p->join), '3rd snippet join');
ok(!($p->final), '3rd snippet final');
is($p->start_page, 4, 'Start page is set');
is($p->end_page, 7, 'End page is set');

$p = $doc->snippet(3);
is($p->content, q{ #.#PB=8#.~  Und wenn wir dann in Berlin sind, dann bin ich für Hofball und Galaoper, immer dicht neben der großen Mittelloge.«}, '4th snippet text');
ok($p->join, '4th snippet join');
ok($p->final, '4th snippet final');
is($p->start_page, 8, 'Start page is set');
is($p->end_page, 8, 'End page is set');

done_testing;
__END__
