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

use_ok('Rabbid::Command::rabbid_convert');

my $t = Test::Mojo->new;
my $app = $t->app;

ok(my $cmd = Rabbid::Command::rabbid_convert->new, 'Create object');
$cmd->app($app);

is($cmd->description, 'Convert documents to RabbidML files', 'Desc');
like(my $usage = $cmd->usage, qr!usage: perl script/rabbid rabbid_convert!, 'Usage');

stdout_is(
  sub { $cmd->run },
  $usage,
  'Show usage'
);

my $file = catfile(dirname(__FILE__), 'data', 'goe-example.i5');

stdout_like(
  sub { $cmd->run('-f', $file)},
  qr/(?:Converted.+?goe-agx-0000[12]\.rabbidml.+?){2}/s,
  'Convert I5'
);

$file = catfile(dirname(__FILE__), 'data', 'pg5323.txt');

stderr_like(
  sub { $cmd->run('-f', $file)},
  qr/unable to parse/si,
  'Convert I5'
);

my $output = stdout_from(sub { $cmd->run('-f', $file, '-x', 'Guttenberg') });

my $pattern = qr!Converted (.+?pg5323\.rabbidml)!;
like($output, $pattern, 'Convert Guttenberg');
$output =~ $pattern;

my $dom = Mojo::DOM->new->xml(1)->parse(slurp($1));
is($dom->at('title')->text, 'Effi Briest');

done_testing;
__END__




