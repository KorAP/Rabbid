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
  ->text_is('p.total-results span', 4)
  ->text_is('ol.kwic li:nth-of-type(1) mark', 'liebe')
  ->text_like('ol.kwic li:nth-of-type(1) p.ref', qr!Woyzeck!)
  ->text_is('ol.kwic li:nth-of-type(2) mark', 'Liebe')
  ->text_like('ol.kwic li:nth-of-type(2) p.ref', qr!Woyzeck!)
  ->text_is('ol.kwic li:nth-of-type(3) mark', 'lieber')
  ->text_like('ol.kwic li:nth-of-type(3) p.ref', qr!Woyzeck!)
  ->text_is('ol.kwic li:nth-of-type(4) mark', 'lieb')
  ->text_like('ol.kwic li:nth-of-type(4) p.ref', qr!Woyzeck!);

# Effi Briest
ok($app->rabbid_import('example' => _p('pg5323')), 'Import example data');

$t->get_ok('/corpus')
  ->status_is(200)
  ->element_count_is('table.oro-view tbody tr', 2);

$t->get_ok('/search?q=Liebe')
  ->status_is(200)
  ->text_like('h3', qr/Liebe/)
  ->text_is('p.total-results span', 171)
  ->text_is('ol.kwic li:nth-of-type(1) mark', 'Liebe')
  ->text_like('ol.kwic li:nth-of-type(1) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(2) mark', 'Liebe')
  ->text_like('ol.kwic li:nth-of-type(2) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(3) mark', 'lieber')
  ->text_like('ol.kwic li:nth-of-type(3) p.ref', qr!Fontane!)
  ->text_is('ol.kwic li:nth-of-type(4) mark', 'lieber')
  ->text_like('ol.kwic li:nth-of-type(4) p.ref', qr!Fontane!);

done_testing;

__END__


my @files = ();
foreach (qw//) { # pg35312 pg38780 pg5323/) {
  push @files, catfile(dirname(__FILE__), 'example', $_ . '.html');
};
