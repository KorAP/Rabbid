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

use_ok('Rabbid::Convert::Guttenberg');

my $file = catfile(dirname(__FILE__), 'data', 'pg5323.txt');

my $temp_out = tempdir(CLEANUP => 1);

my $c = Rabbid::Convert::Guttenberg->new(
  input => $file,
  output => $temp_out,
  id_offset => 5
);

my @files = $c->convert;

is(scalar @files, 1, 'One document converted');

ok(-e $files[0], 'One document loadable');

my $dom = Mojo::DOM->new->xml(1)->parse(slurp $files[0]);

ok($dom, 'File is parsed');

is($dom->at('title')->text, 'Effi Briest');

ok($dom->at('meta[name=doc_id][content=5]'), 'Element exists');

is($dom->at('meta[name=url]')->attr('content'), encode('utf-8', "http://www.gutenberg.org/5/3/2/5323/"), 'Element exists');

is($dom->find('p')->[2]->text, encode('UTF-8', 'Erstes Kapitel'), 'Text');
like($dom->find('p')->[4]->at('span')->text, qr/Herrenhauses/, 'Text');
is($dom->find('p')->[7]->text, encode('UTF-8', '»Möchtest du\'s?«'), 'Text');

done_testing;
__END__
