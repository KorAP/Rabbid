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

$t->app->rabbid->init;

ok(my $fields = $app->rabbid->corpus->fields, 'Fields');
is($fields->[0], 'author');
is($fields->[-1], 'file');

done_testing;

__END__
