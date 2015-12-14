use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use lib '../lib', 'lib';

$ENV{MOJO_MODE} = 'test';

my $t = Test::Mojo->new('Rabbid');

$t->get_ok('/')
  ->status_is(200)
  ->text_is('h1 span', 'Rabbid')
  ->element_exists('a.collections')
  ->element_exists('a.overview')
  ->element_exists('a.search')
  ->element_exists('a.about');

done_testing;

__END__

$t->get_ok('/?q=Darmstädtler')
  ->status_is(200);

$t->get_ok('/?q=Baum')
  ->status_is(200);

$t->get_ok('/?q=Darmstadt')
  ->status_is(200);

$t->get_ok('/?q=Niedergang')
  ->status_is(200);

$t->get_ok('/?q=Fragen')
  ->status_is(200);

done_testing();
