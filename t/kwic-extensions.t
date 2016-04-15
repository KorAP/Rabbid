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
  ->element_exists('ol.kwic li:nth-of-type(1)[data-id=3][data-para=0]')
  ;

$t->get_ok('/corpus/3/0')
  ->json_is('/para', 0)
  ->json_is('/next', 1)
  ->json_is('/in_doc_id', 3)
  ->json_is('/content', q{»Liebe Effi! ... So fängt es nämlich immer an, und manchmal nennt er mich auch seine 'kleine Eva'.«})
  ;

$t->get_ok('/corpus/3/1')
  ->json_is('/para', 1)
  ->json_is('/next', 2)
  ->json_is('/in_doc_id', 3)
  ->json_is('/content', q{»Freilich ist das die Hauptsache, 'Weiber weiblich, Männer männlich' - das ist, wie ihr wißt, einer von Papas Lieblingssätzen. Und nun helft mir erst Ordnung schaffen auf dem Tisch hier, sonst gibt es wieder eine Strafpredigt.«})
  ;


done_testing;

__END__
