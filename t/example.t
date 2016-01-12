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
my @files = ();
foreach (qw/5322-0 pg35312 pg38780 pg5323/) {
  push @files, catfile(dirname(__FILE__), 'example', $_ . '.html');
};
ok($app->rabbid_import('example' => @files), 'Import example data');

$t->get_ok('/corpus')
  ->status_is(200)
  ->element_count_is('table.oro-view tbody tr', 4);

done_testing;
