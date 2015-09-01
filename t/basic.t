use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use lib '../lib', 'lib';

# Todo: use .test environment!
my $t = Test::Mojo->new('Rabbid');
$t->get_ok('/')
  ->status_is(200);

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
