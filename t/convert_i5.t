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
  $x++ if (-e $_);
};
is($x, 3, 'Three documents loadable');

my $dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]);

ok($dom, 'File is parsed');
is($dom->at('title')->text, 'Energiewirtschaft');
ok(!$dom->at('meta[name=corpus_s][content=REI]'), 'Element exists not');
ok($dom->at('meta[name=corpus_sigle][content=REI]'), 'Element exists');
ok($dom->at('meta[name=text_class][content=politik inland]'), 'Element exists');
ok($dom->at('meta[name=doc_sigle][content=REI/BNG]'), 'Element exists');
ok($dom->at('meta[name=pub_place][content=Berlin]'), 'Element exists');
ok($dom->at('meta[name=doc_id][content=1]'), 'Element exists');
is($dom->at('meta[name=doc_title]')->attr('content'), encode('utf-8', "Reden der Bundestagsfraktion Bündnis 90/DIE GRÜNEN, (2002-2006)"), 'Element exists');

$dom = Mojo::DOM->new->xml(1)->parse(slurp $files[1]);
ok($dom, 'File is parsed');
is($dom->at('title')->text, 'Insolvenzantrag Kirch Media AG');
ok($dom->at('meta[name=doc_id][content=2]'), 'Doc id');

is($dom->find('p')->[5]->text, encode('UTF-8', 'Die schnelle Verabschiedung dieses Gesetzes ist notwendig, da wir immer noch säumig sind in der Umsetzung der EU-Gasrichtlinie.'), 'Text');

use_ok('Rabbid::Command::rabbid_convert');

done_testing;
__END__
