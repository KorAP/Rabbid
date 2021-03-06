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

$t->app->rabbid->init;

$t->get_ok('/')
  ->status_is(200)
  ->text_is('h1 span', 'Rabbid')
  ->element_exists('a.collections.active')
  ->element_exists('a.overview')
  ->element_exists('a.search')
  ->element_exists('a.about')
  ->element_exists('div#happy');

$t->get_ok('/corpus')
  ->status_is(200)
  ->text_is('h1 span', 'Rabbid')
  ->element_exists('a.collections')
  ->element_exists('a.overview.active')
  ->element_exists('a.search')
  ->element_exists('a.about')
  ->element_exists('table.oro-view tbody')
  ->element_exists_not('table.oro-view tbody tr');

# Add example data
my $app = $t->app;
my @files = ();
foreach (qw/text1 text2/) {
  push @files, catfile(dirname(__FILE__), 'data', $_ . '.rabbidml');
};
ok($app->rabbid->import('example' => @files), 'Import example data');

$t->get_ok('/corpus')
  ->status_is(200)
  ->text_is('table.oro-view thead tr th:nth-of-type(1) a', '#')
  ->text_is('table.oro-view thead tr th:nth-of-type(2) a', 'Verfasser')
  ->text_is('table.oro-view thead tr th:nth-of-type(3) a', 'Titel')
  ->text_is('table.oro-view thead tr th:nth-of-type(4) a', 'Jahr')
  ->text_is('table.oro-view thead tr th:nth-of-type(5) a', 'Spektrum')
  ->text_is('table.oro-view thead tr th:nth-of-type(6) a', 'Domäne')
  ->text_is('table.oro-view thead tr th:nth-of-type(7) a', 'Textsorte')
  ->text_is('table.oro-view thead tr th:nth-of-type(8) a span', 'file')
  ->element_exists('table.oro-view tfoot tr td.pagination[colspan=8]')

  ->text_is('table.oro-view tbody tr td:nth-of-type(1) a', 1)
  ->text_is('table.oro-view tbody tr td:nth-of-type(2) a', 'Max Mustermann')
  ->text_is('table.oro-view tbody tr td:nth-of-type(3) a', 'Example 1')
  ->text_is('table.oro-view tbody tr td:nth-of-type(4) a', '1919')
  ->text_is('table.oro-view tbody tr td:nth-of-type(5)', '')
  ->text_is('table.oro-view tbody tr td:nth-of-type(6)', '')
  ->text_is('table.oro-view tbody tr td:nth-of-type(7)', '')

  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(1) a', 2)
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(2) a', 'Theodor Fontane')
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(3) a', 'Example 2')
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(4) a', '1894')
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(5)', '')
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(6) a', 'Roman')
  ->text_is('table.oro-view tbody tr:nth-of-type(2) td:nth-of-type(7) a', 'Belletristik');

$t->get_ok('/about')
  ->status_is(200)
  ->text_is('h3', 'Impressum');

# Check tests
$t->get_ok('/search?q=test')
  ->status_is(200)
  ->text_is('div#search > div > p', 'Leider keine Treffer ...')
  ->text_is('div.pagination a[rel=self]', '[1]');

# Check tests
$t->get_ok('/search?q=beispiel')
  ->status_is(200)
  ->element_exists('ol.kwic li[data-id=2] div.snippet')
  ->text_is('ol.kwic li div.snippet mark', 'Beispiel')
  ->text_is('ol.kwic li p.ref a', 'Roman');

# Check tests
$t->get_ok('/search?q=tschüß')
  ->status_is(200)
  ->element_exists('ol.kwic li[data-id=1] div.snippet')
  ->text_is('ol.kwic li[data-id=1] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=1] p.ref', qr!Max Mustermann: Example 1\s*\(1919\);!)
  ->element_exists('ol.kwic li[data-id=2] div.snippet')
  ->text_is('ol.kwic li[data-id=2] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=2] p.ref', qr!Theodor Fontane: Example 2\s*\(1894\);!);

$t->get_ok('/search?q=echt')
  ->text_is('ol.kwic div.snippet span.match mark', 'Echt');

$t->get_ok('/search?q=echt?startPage=45')
  ->text_like('div#search div p', qr!^Leider!);

done_testing;

__END__



