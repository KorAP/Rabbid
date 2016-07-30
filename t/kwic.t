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

$t->app->rabbid_init;

# Add example data
my $app = $t->app;
ok($app->rabbid_import('example' => catfile(dirname(__FILE__), 'data/text3.html')), 'Import example data');

# Check tests
$t->get_ok('/search?q=Liebe')
  ->status_is(200)
  ->text_is('ol.kwic li:nth-of-type(1) mark:nth-of-type(1)', 'Liebe')
  ->text_is('ol.kwic li:nth-of-type(2) mark:nth-of-type(1)', 'Liebe')
  ->text_is('ol.kwic li:nth-of-type(2) mark:nth-of-type(2)', 'Liebe')
  ->text_is('ol.kwic li:nth-of-type(2) mark:nth-of-type(3)', 'Liebe')
  ;

ok($app->rabbid_import('example' => catfile(dirname(__FILE__), 'data/text1.html')), 'Import example data');
ok($app->rabbid_import('example' => catfile(dirname(__FILE__), 'data/text2.html')), 'Import example data');

# Check tests
$t->get_ok('/search?q=tschüß')
  ->status_is(200)
  ->element_exists('ol.kwic li[data-id=1] div.snippet')
  ->text_is('ol.kwic li[data-id=1] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=1] p.ref', qr!^Max Mustermann: Example 1\s*\(1919\);!)
  ->element_exists('ol.kwic li[data-id=2] div.snippet')
  ->text_is('ol.kwic li[data-id=2] div.snippet span.match mark', 'Tschüß')
  ->text_like('ol.kwic li[data-id=2] p.ref', qr!^Theodor Fontane: Example 2\s*\(1894\);!);

# Check tests
$t->get_ok('/search?q=manchmal')
  ->element_exists('ol li[data-id=3][data-start-page=1][data-end-page=3]');

$t->get_ok('/search?q=gnädig')
  ->element_exists('ol li[data-id=3][data-start-page=4][data-end-page=7]');

done_testing;

__END__
