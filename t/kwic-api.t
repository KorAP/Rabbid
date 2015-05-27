use Mojo::Base -strict;
use utf8;
use lib '../lib', 'lib';

use Test::More;
use Test::Mojo;
use Mojo::ByteStream 'b';

my $t = Test::Mojo->new('Rael');
$t->get_ok('/corpus/doc/test')->status_is(404);

$t->get_ok('/corpus/doc/test?start=1611&end=1853')
  ->status_is(200)
  ->json_is('/snippet', b('Altwandervogel Wandervogel Großdeutscher Pfadfinderbund')->encode)
  ->json_is('/start', 1611)
  ->json_is('/end', 1853)
  ->json_is('/id', 'p000003');

$t->get_ok('/corpus/doc/test?start=1611&end=1853&q=großdeutsche')
  ->status_is(200)
  ->json_is('/snippet', b('Altwandervogel Wandervogel <mark>Großdeutscher</mark> Pfadfinderbund')->encode)
  ->json_is('/start', 1611)
  ->json_is('/end', 1853)
  ->json_is('/id', 'p000003');

$t->get_ok('/corpus/doc/test?start=1611&end=1853&q=grossdeutscher')
  ->status_is(200)
  ->json_is('/snippet', b('Altwandervogel Wandervogel <mark>Großdeutscher</mark> Pfadfinderbund')->encode)
  ->json_is('/start', 1611)
  ->json_is('/end', 1853)
  ->json_is('/id', 'p000003');

done_testing();
