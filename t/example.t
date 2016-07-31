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
$app->rabbid_init;

sub _p {
  return catfile(dirname(__FILE__), 'example', $_[0] . '.html');
};

# Woyzeck
ok($app->rabbid_import('example' => _p('5322-0')), 'Import example data');

$t->get_ok('/corpus')
  ->status_is(200)
  ->element_count_is('table.oro-view tbody tr', 1);

$t->get_ok('/search?q=Liebe')
  ->status_is(200)
  ->text_like('h3', qr/Liebe/)
  ->text_like('li[data-id=4] p.ref', qr/Georg Büchner/)
  ->text_is('li[data-id=4] p.ref a:nth-of-type(1)', 'revolutionär');


# Effi Briest
ok($app->rabbid_import('example' => _p('pg5323')), 'Import example data');

$t->get_ok('/corpus')
  ->status_is(200)
  ->element_count_is('table.oro-view tbody tr', 2);

$t->get_ok('/search?q=Liebe')
  ->status_is(200)
  ->text_like('h3', qr/Liebe/)
  ->text_is('p.total-results span', 171)
  ->text_is('ol.kwic li:nth-of-type(1) mark:nth-of-type(1)', 'Liebe')
  ->text_like('ol.kwic li:nth-of-type(1) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(2) mark', 'Liebe')
  ->text_like('ol.kwic li:nth-of-type(2) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(3) mark', 'lieber')
  ->text_like('ol.kwic li:nth-of-type(3) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(4) mark', 'lieber')
  ->text_like('ol.kwic li:nth-of-type(4) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li[data-para=152] mark:nth-of-type(1)', 'Liebe')
  ->text_is('ol.kwic li[data-para=152] mark:nth-of-type(2)', 'Liebe')
  ->text_is('ol.kwic li[data-para=152] mark:nth-of-type(3)', 'Liebe')
  ->text_is('ol.kwic li[data-para=161] mark', 'Liebe')
;

ok($app->rabbid_import('example' => _p('pg38780')), 'Import example data');

$t->get_ok('/corpus')
  ->text_like('tbody tr:nth-of-type(2) td:nth-of-type(3)', qr/zufälligen Makulaturblättern/)
  ->text_is('tbody tr:nth-of-type(3) td:nth-of-type(2)', 'Georg Büchner')
;

# ok($app->rabbid_import('example' => _p('pg35312')), 'Import example data');

done_testing;

__END__

