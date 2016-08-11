use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Test::Output qw/:stdout :stderr :functions/;
use Test::More;
use File::Temp qw/tempfile tempdir/;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use Mojo::DOM;
use Mojo::Util qw/slurp/;

use_ok('Rabbid::Command::rabbid_import');

# Use test configuration
$ENV{MOJO_MODE} = 'test';

my $t = Test::Mojo->new('Rabbid');
my $app = $t->app;

ok(my $cmd = Rabbid::Command::rabbid_import->new, 'Create object');
$cmd->app($app);

is($cmd->description, 'Import RabbidML files', 'Desc');
like(my $usage = $cmd->usage, qr!usage: perl script/rabbid rabbid_import!, 'Usage');

ok($app->config('Corpora')->{example}, 'example corpus defined');
is($app->config('Oro')->{default}->{file}, ':memory:', 'Database is in memory');

if ($app->config('Oro')->{default}->{file} ne ':memory:') {
  die 'Database is not temporary - won\'t import';
};

stdout_is(
  sub { $cmd->run },
  $usage,
  'Show usage'
);

my @files = (
  catfile(dirname(__FILE__), 'example', '5322-0.rabbidml'),
  catfile(dirname(__FILE__), 'example', 'pg5323.rabbidml')
);

stdout_like(
  sub { $cmd->run('-f', $files[0], '-f', $files[1]) },
  qr/Failed imports: 2/,
  'Show Import of two files'
);


# Database not initialized
{
  $SIG{__WARN__} = sub {};
  stdout_like(
    sub { $cmd->run('-f', $files[0], '-f', $files[1], '-c', 'example' )},
    qr/Failed imports: 2/,
    'Show Import of two files'
  );
};

# Initialize database
$app->rabbid_init;

stdout_like(
  sub { $cmd->run('-f', $files[0], '-f', $files[1], '-c', 'example' )},
  qr/(?:Import.+?(?:5322-0|pg5323)\.rabbidml.+?){2}/s,
  'Show Import of two files'
);


done_testing;
__END__
