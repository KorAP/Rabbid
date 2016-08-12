use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::DOM;
use utf8;
use Mojo::Util qw/slurp encode/;
use lib '../lib', 'lib';
use File::Temp qw/tempfile tempdir/;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;

use_ok('Rabbid::Convert::I5');

my $file = catfile(dirname(__FILE__), 'data', 'rei-example.i5');

my $temp_out = tempdir(CLEANUP => 1);

my $c = Rabbid::Convert::I5->new(
  input => $file,
  output => $temp_out
);

my @files = $c->convert;

is(scalar @files, 3, 'Three documents converted');

my $x = 0;
foreach (@files) {
  $x++ if (-e $_->[0]);
};
is($x, 3, 'Three documents loadable');

my $dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]->[0]);

ok($dom, 'File is parsed');
is($dom->at('title')->text, 'Energiewirtschaft');
ok(!$dom->at('meta[name=corpus_s][content=REI]'), 'Element exists not');
ok($dom->at('meta[name=corpus_sigle][content=REI]'), 'Element exists');
ok($dom->at('meta[name=text_class][content=politik inland]'), 'Element exists');
ok($dom->at('meta[name=doc_sigle][content=REI/BNG]'), 'Element exists');
ok($dom->at('meta[name=pub_place][content=Berlin]'), 'Element exists');
ok($dom->at('meta[name=doc_id][content=1]'), 'Element exists');
is($dom->at('meta[name=doc_title]')->attr('content'), encode('utf-8', "Reden der Bundestagsfraktion Bündnis 90/DIE GRÜNEN, (2002-2006)"), 'Element exists');
is($dom->find('p')->[2]->find('span')->[2]->text, encode('UTF-8', 'Die schnelle Verabschiedung dieses Gesetzes ist notwendig, da wir immer noch säumig sind in der Umsetzung der EU-Gasrichtlinie.'), 'Text');

$dom = Mojo::DOM->new->xml(1)->parse(slurp $files[1]->[0]);
ok($dom, 'File is parsed');
is($dom->at('title')->text, 'Insolvenzantrag Kirch Media AG');
ok($dom->at('meta[name=doc_id][content=2]'), 'Doc id');
is($dom->find('p')->[2]->find('span')->[2]->text, encode('UTF-8', 'Herr Wiesheu, es gibt anscheinend einige größere Unterschiede zwischen dem Bayerischen Landtag und diesem Parlament.'), 'Text');

# Goethe mit pagebreaks
$file = catfile(dirname(__FILE__), 'data', 'goe-example.i5');
$c = Rabbid::Convert::I5->new(
  input => $file,
  output => $temp_out,
  id_offset => 4
);

@files = $c->convert;
is(scalar @files, 2, 'Two documents converted');

$x = 0;
foreach (@files) {
  $x++ if (-e $_->[0]);
};
is($x, 2, 'Three documents loadable');

$dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]->[0]);
ok($dom, 'File is parsed');
is($dom->at('title')->text, 'Maximen und Reflexionen');
ok($dom->at('meta[name=corpus_sigle][content=GOE]'), 'Element exists');
ok($dom->at('meta[name=doc_id][content=4]'), 'Element exists');
ok($dom->at('meta[name=author][content=Goethe, Johann Wolfgang von]'), 'Element exists');

ok(my $body = $dom->at('body'), 'Defined body');

is($dom->find('p')->[0],
   '<p><span><br class="pb" data-after="365" />Maximen und Reflexionen</span></p>', 'Text');

is($dom->find('p')->[1],
   '<p><span>Gott und Natur.</span></p>', 'Text');

is($dom->find('p')->[2]->at('span')->text,
   encode('utf-8',
	  '"ich glaube einen Gott!" dies ist ein schönes löbliches Wort; '.
	    'aber Gott anerkennen, wo und wie er sich offenbare, '.
	      'das ist eigentlich die Seligkeit auf Erden.'
	    ), 'Text');

done_testing;
__END__
