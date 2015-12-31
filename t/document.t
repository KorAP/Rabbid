use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use utf8;
use lib '../lib', 'lib';
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

my $file = catfile(dirname(__FILE__), 'data', 'text1.html'),

use_ok('Rabbid::Document');

ok(my $doc = Rabbid::Document->new($file), 'Load document');

is($doc->meta('doc_id'), 1, 'Document ID');
is($doc->meta('author'), 'Max Mustermann', 'Author');
is($doc->meta('year'), '1919', 'Year');

is($doc->title, 'Example 1', 'Title');

my $p = $doc->snippet(0);
is($p->content, 'Dies ist ein Beispieltext.', '1st snippet text');
ok(!($p->join), '1st snippet join');
ok(!($p->final), '1st snippet final');

$p = $doc->snippet(1);
is($p->content, 'Er soll lediglich illustrieren, wie Rabbid funktioniert.', '2nd snippet text');
ok(!($p->join), '2nd snippet join');
ok(!($p->final), '2nd snippet final');

$p = $doc->snippet(2);
is($p->content, 'Nichts weiter.', '3rd snippet text');
ok($p->join, '3rd snippet join');
ok(!($p->final), '3rd snippet final');

$p = $doc->snippet(3);
is($p->content, 'Tschüß!', '4th snippet text');
ok(!($p->join), '4th snippet join');
ok($p->final, '4th snippet final');

ok($doc->snippet(1)->id != $doc->snippet(2)->id, 'Identifier change');

done_testing;
