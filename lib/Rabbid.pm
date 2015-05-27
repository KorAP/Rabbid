package Rabbid;
use Mojo::Base 'Mojolicious';
use Mojo::ByteStream 'b';
use Lingua::Stem::UniNE::DE qw/stem_de/;
use Cache::FastMmap;

our $VERSION = '0.1.0';

# 120 seconds inactivity allowed
$ENV{MOJO_INACTIVITY_TIMEOUT} = 120;

# This method will run once at server start
sub startup {
  my $self = shift;

  push @{$self->commands->namespaces}, __PACKAGE__ . '::Command';

  $self->types->type(rtf => 'application/rtf');

  $self->defaults(
    title => 'Rabbid',
    description => 'Recherche- und Analyse-Basis für Belegstellen in Diskursen'
  );

  $self->plugin('CHI' => {
    default => {
      driver     => 'FastMmap',
      root_dir   => $self->home . '/cache',
      cache_size => '20m'
    }
  });


  $self->plugin(Oro => {
    default => {
      file => $self->home .'/db/rabbid.sqlite',
      attached => {
	coll => $self->home . '/db/collection.sqlite'
      }
    }
  });

  $self->plugin('TagHelpers::Pagination' => {
    separator => '',
    ellipsis => '<span class="ellipsis">...</span>',
    current => '<span class="current">[{current}]</span>',
    page => '<span class="page-nr">{page}</span>',
    next => '<span>&gt;</span>',
    prev => '<span>&lt;</span>'
  });

  $self->plugin('Oro::Viewer' => {
    default_count => 25,
    max_count => 100
  });

  $self->helper(
    hidden_parameters => sub {
      my $c = shift;
      my %param = @_;
      my (%with, %without);
      if ($param{with}) {
	$with{$_} = 1 foreach @{$param{with}};
      };
      if ($param{without}) {
	$without{$_} = 1 foreach @{$param{without}};
      };
      my $tag = '';
      foreach (@{ $c->req->params->names }) {
	if ((!$param{with} && !$without{$_}) || $with{$_}) {
	  $tag .= $c->hidden_field($_ => scalar $c->param($_)) . "\n";
	};
      };
      return b $tag;
    }
  );

  $self->helper(
    filter_by => sub {
      my $c = shift;
      my ($key, $value) = @_;
      return $c->link_to(
	$value,
	$c->url_with->query([
	  startPage => 1,
	  filterBy => $key,
	  filterOp => 'equals',
	  filterValue => $value
	])
      );
    }
  );

  $self->helper(
    stem => sub { return stem_de pop }
  );

  # Router
  my $r = $self->routes;

  # Normal route to controller
  # $r->get('/')->to('Index#search');

  $r->get('/')->to('Document#overview', overview => 1)->name('corpus');
  $r->get('/search')->to('Search#kwic', search => 1)->name('search');
  $r->get('/corpus/raw/:file')->name('file');
  $r->get(
    '/corpus/:doc_id/:para',
    [doc_id => qr/\d+/, para => qr/\d+/]
  )->to('Search#snippet')->name('snippet');
  $r->post(
    '/corpus/:doc_id/:para',
    [doc_id => qr/\d+/, para => qr/\d+/]
  )->to('Collection#store');
  $r->get('/collection')->to('Collection#index', collection => 1)->name('collection');
};

1;
