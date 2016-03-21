use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use utf8;
use lib '../lib', 'lib';
use Rabbid::Corpus;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

$ENV{MOJO_MODE} = 'test';

my $t = Test::Mojo->new('Rabbid');

# Add example data
my $app = $t->app;

$t->app->rabbid_init;

my @files = ();
foreach (qw/text1 text2/) {
  push @files, catfile(dirname(__FILE__), 'data', $_ . '.html');
};
ok($app->rabbid_import('example' => @files), 'Import example data');

# Check tests
$t->get_ok('/search?q=tschüß')
  ->status_is(200)
  ->element_exists('ol.kwic li[data-id=1] div.snippet')
  ->text_is('ol.kwic li[data-id=1] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=1] p.ref', qr!^Max Mustermann: Example 1[\s\n]*\(1919\);!)
  ->element_exists('ol.kwic li[data-id=2] div.snippet')
  ->text_is('ol.kwic li[data-id=2] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=2] p.ref', qr!^Theodor Fontane: Example 2[\s\n]*\(1894\);!)
  ->text_is('p.total-results > span', 2);

# Store in collection
$t->post_ok('/corpus/2/3' => json => {
  leftExt => 0,
  rightExt => 0,
  q => 'tschüß',
  marks => '2 0 0 8'
})
  ->status_is(200)
  ->json_is('/msg', 'stored')
  ->json_is('/marks', '2 0 0 8')
  ->json_is('/rightExt', 0)
  ->json_is('/doc_id', 2)
  ->json_is('/coll_id', undef)
  ->json_is('/para', 3)
  ->json_is('/leftExt', 0);

# Repeatedly store in collection
$t->post_ok('/corpus/2/3' => json => {
  leftExt => 0,
  rightExt => 0,
  q => 'tschüß',
  marks => '2 0 0 8'
})
  ->status_is(200)
  ->json_is('/msg', 'stored')
  ->json_is('/marks', '2 0 0 8')
  ->json_is('/rightExt', 0)
  ->json_is('/doc_id', 2)
  ->json_is('/coll_id', undef)
  ->json_is('/para', 3)
  ->json_is('/leftExt', 0);

# Again store a different match in collection
$t->post_ok('/corpus/1/4' => json => {
  leftExt => 0,
  rightExt => 0,
  q => 'tschüß',
  marks => '2 0 0 8'
})
  ->status_is(200)
  ->json_is('/msg', 'stored')
  ->json_is('/marks', '2 0 0 8')
  ->json_is('/rightExt', 0)
  ->json_is('/doc_id', 1)
  ->json_is('/coll_id', undef)
  ->json_is('/para', 4)
  ->json_is('/leftExt', 0);

# Next stored collection
$t->get_ok('/search?q=Rabbid')
  ->status_is(200)
  ->text_is('p.total-results span', 1)
  ->element_exists('li[data-id=1][data-para=1][data-marks="2 0 36 6"]');

# Expand!
$t->get_ok('/corpus/1/1')
  ->status_is(200)
  ->json_is('/content', 'Er soll lediglich illustrieren, wie Rabbid funktioniert.')
  ->json_is('/previous', 0)
  ->json_is('/next', 2)
  ->json_is('/para', 1)
  ->json_is('/nobr', undef)
  ->json_is('/in_doc_id', 1)
;

$t->get_ok('/corpus/1/2')
  ->status_is(200)
  ->json_is('/content', 'Nichts weiter.')
  ->json_is('/previous', 1)
  ->json_is('/next', 3)
  ->json_is('/para', 2)
  ->json_is('/nobr', 'nobr')
  ->json_is('/in_doc_id', 1)
;

sleep(1); # This is necessary to correctly order the collections

$t->post_ok('/corpus/1/1' => json => {
  leftExt => 0,
  rightExt => 1,
  q => 'Rabbid',
  marks => '2 0 36 6'
})
  ->status_is(200)
  ->json_is('/msg', 'stored')
  ->json_is('/marks', '2 0 36 6')
  ->json_is('/rightExt', 1)
  ->json_is('/doc_id', 1)
  ->json_is('/coll_id', undef)
  ->json_is('/para', 1)
  ->json_is('/leftExt', 0);

$t->get_ok('/')
  ->status_is(200)
  ->text_is('h3', 'Kollektionen')
  ->text_is('ol.collection li:nth-of-type(1) a', 'Rabbid')
  ->text_is('ol.collection li:nth-of-type(1)', '(1 Belegstelle)')
  ->text_is('ol.collection li:nth-of-type(2) a', 'tschüß')
  ->text_is('ol.collection li:nth-of-type(2)', '(2 Belegstellen)')
  ;

$t->get_ok('/collection/1')
  ->status_is(200)
  ->text_is('h3', 'Kollektion "tschüß"')
  ->element_count_is('ol.kwic li', 2)
  ;

done_testing;
__END__

