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
  push @files, catfile(dirname(__FILE__), 'data', $_ . '.rabbidml');
};
ok($app->rabbid_import('example' => @files), 'Import example data');

# Check tests
$t->get_ok('/search?q=tschüß')
  ->status_is(200)
  ->element_exists('ol.kwic li[data-id=1] div.snippet')
  ->text_is('ol.kwic li[data-id=1] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=1] p.ref', qr!^Max Mustermann:\s*Example 1[\s\n]*\(1919\);!)
  ->element_exists('ol.kwic li[data-id=2] div.snippet')
  ->text_is('ol.kwic li[data-id=2] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=2] p.ref', qr!^Theodor Fontane:\s*Example 2[\s\n]*\(1894\);!)
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
  ->json_is('/leftExt', 0)
  ;

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
#  ->json_is('/previous', 0)
#  ->json_is('/next', 2)
  ->json_is('/para', 1)
  ->json_is('/nobr', undef)
  ->json_is('/in_doc_id', 1)
;

$t->get_ok('/corpus/1/2')
  ->status_is(200)
  ->json_is('/content', 'Nichts weiter - öhrlich!')
#  ->json_is('/previous', 1)
#  ->json_is('/next', 3)
  ->json_is('/para', 2)
  ->json_is('/nobr', 'nobr')
  ->json_is('/in_doc_id', 1)
;

sleep(1);
# This is necessary to correctly order the collections

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
  ->text_is('ol.collection li:nth-of-type(1)', ' (1 Belegstelle)')
  ->text_is('ol.collection li:nth-of-type(2) a', 'tschüß')
  ->text_is('ol.collection li:nth-of-type(2)', ' (2 Belegstellen)')
  ;

$t->get_ok('/collection/1')
  ->status_is(200)
  ->text_is('h3', 'Kollektion "tschüß"')
  ->element_count_is('ol.kwic li', 2)
  ->element_exists('input[name=q][value=tschüß]')
  ->text_is('div.pagination a[rel=self]', '[1]')
  ;

$t->get_ok('/collection/2')
  ->status_is(200)
  ->text_is('h3', 'Kollektion "Rabbid"')
  ->element_count_is('ol.kwic li', 1)
  ->element_exists('input[name=q][value=Rabbid]')
  ->text_is('div.pagination a[rel=self]', '[1]')
  ->text_is('li[data-id=1] span mark', 'Rabbid')
  ->text_is('li[data-id=1] span.ext', 'Nichts weiter - öhrlich!')
  ;




# Example for large collection
ok($app->rabbid_import('example' => catfile(dirname(__FILE__), 'example', 'pg38780.rabbidml')), 'Import example data');

# Check tests
my $q = 'ist';
my $ua = $t->ua;
my $found = 0;

my $dom = $t->get_ok('/search?q=' . $q)
  ->status_is(200)
    ->text_is('p.total-results > span', 462)
  ->tx->res->dom;

$dom->find('ol.kwic > li')->each(
  sub {
    my $e = shift;
    my $id = $e->attr('data-id');
    my $para = $e->attr('data-para');
    my $j = $ua->post('/corpus/'.$id.'/' . $para => json => {
      q => $q,
      marks => $e->attr('data-marks')
    })->res->json('/msg');
    $found++ if $j eq 'stored';
  });

is($found, 20, 'Found');

$dom = $t->get_ok('/search?q=' . $q . '&page=2')
  ->status_is(200)
    ->text_is('p.total-results > span', 462)
  ->tx->res->dom;

$dom->find('ol.kwic > li')->each(
  sub {
    my $e = shift;
    return if $found >= 30;
    my $id = $e->attr('data-id');
    my $para = $e->attr('data-para');
    my $j = $ua->post('/corpus/'.$id.'/' . $para => json => {
      q => $q,
      marks => $e->attr('data-marks')
    })->res->json('/msg');
    $found++ if $j eq 'stored';
  });

is($found, 30, 'Found');

$t->get_ok('/')
  ->status_is(200)
  ->text_is('h3', 'Kollektionen')
  ->text_is('ol.collection li:nth-of-type(1) a', 'ist')
  ->text_is('ol.collection li:nth-of-type(1)', ' (30 Belegstellen)')
  ->text_is('ol.collection li:nth-of-type(2) a', 'Rabbid')
  ->text_is('ol.collection li:nth-of-type(2)', ' (1 Belegstelle)')
  ->text_is('ol.collection li:nth-of-type(3) a', 'tschüß')
  ->text_is('ol.collection li:nth-of-type(3)', ' (2 Belegstellen)')
  ->text_is('a[href=/collection/3?q=ist]', 'ist')
  ;

$t->get_ok('/collection/3')
  ->status_is(200)
  ->text_is('h3', 'Kollektion "ist"')
  ->element_count_is('ol.kwic li', 20)
  ->element_exists('input[name=q][value=ist]')
  ->text_is('div.pagination a[rel=self]', '[1]')
  ->text_is('a[href][rel=next]', '>')
  ;

$t->get_ok('/collection/3?page=2&q=ist')
  ->status_is(200)
  ->text_is('h3', 'Kollektion "ist"')
  ->element_count_is('ol.kwic li', 10)
  ->element_exists('input[name=q][value=ist]')
  ->text_is('div.pagination a[rel=self]', '[2]')
  ->text_is('a[href][rel=prev]', '<')
  ;


# Check export
$t->get_ok('/collection/3?format=rtf')
  ->status_is(200)
  ->header_is('Content-Type', 'application/rtf;name="Belegstellen-ist.rtf"')
  ->content_like(qr!title Belegstellen-ist!)
  ;

done_testing;
__END__

