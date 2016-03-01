package Rabbid;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.4.0';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Use configuration with default parameter
  $self->plugin('Config' => {
    default => {
      'TagHelpers::Pagination' => {
	separator => '',
	ellipsis => '<span class="ellipsis">...</span>',
	current => '<span class="current">[{current}]</span>',
	page => '<span class="page-nr">{page}</span>',
	next => '<span>&gt;</span>',
	prev => '<span>&lt;</span>'
      },
      'Oro::Viewer' => {
	default_count => 25,
	max_count => 100
      },
      Notifications => {
	Alertify => 1
      },
      CHI => {
	default => {
	  driver => 'Memory',
	  global => 1
	}
      }
    }
  });

  my $config = $self->config;

  $self->secrets($config->{secrets}) if $config->{secrets};

  # 120 seconds inactivity allowed
  $ENV{MOJO_INACTIVITY_TIMEOUT} = 120;

  push @{$self->commands->namespaces}, __PACKAGE__ . '::Command';
  push @{$self->plugins->namespaces},  __PACKAGE__ . '::Plugin';

  # korap.ids-mannheim.de specific path prefixing
  # This can be removed or replaced, if you are running Rabbid
  # below a specific path
  $self->hook(
    before_dispatch => sub {
      my $c = shift;
      my $path = 'rabbid';

      my $host = $c->req->headers->header('X-Forwarded-Host');
      if ($host && $host eq 'korap.ids-mannheim.de') {

	# Set Rabbid path and correct host and port information
	my $base = $c->req->url->base;
	$base->path('/' . $path . '/');
	$base->host($host);
	$base->port(undef);

	# Prefix is used for static assets
	$c->stash(prefix => '/' . $path);
      };
    }) if $self->mode eq 'production';


  # Add richtext format type
  $self->types->type(rtf => 'application/rtf');
  $self->types->type(doc => 'application/msword');

  $self->defaults(
    title => 'Rabbid',
    description => 'Recherche- und Analyse-Basis für Belegstellen in Diskursen',
    layout => 'default'
  );

  # Add plugins
  $self->plugin('Notifications');
  $self->plugin('CHI');
  $self->plugin('RenderFile');
  $self->plugin('ReplyTable');
  $self->plugin('TagHelpers::Pagination');
  $self->plugin('Oro');
  $self->plugin('Oro::Viewer');
  $self->plugin('TagHelpers::ContentBlock');

  my $me = $config->{MailException};
  if ($me) {
    $self->plugin('MailException' => {
      from    => $me->{from},
      to      => $me->{to},
      subject => 'Rabbid crashed!'
    });
  };
  $self->plugin('RabbidHelpers');

  # Rabbid can be configured for multiple users and corpora,
  # but this requires closed source plugins
  my $multi = $self->config('multi');

  # Router
  my $r = $self->routes;

  # There is a rabbid multi plugin defined, establish
  if ($multi) {
    $self->plugin($multi);
    $r = $r->rabbid_multi;
  };

  # Load default plugin
  $self->plugin('RabbidMulti');

  # Collection view
  $r->get('/')->to('Collection#index', collection => 1)->name('home');
  $r->get('/collection/:coll_id')->to(
    'Collection#collection', collection => 1
  )->name('collection');

  # Search view
  $r->get('/search')->to('Search#kwic', search => 1)->name('search');

  # Corpus view
  $r->get('/corpus')->to(
    'Document#overview', overview => 1
  )->name('corpus');
  $r->get('/corpus/raw/:file')->name('file');

  # Ajax API
  # Retrieve snippets
  $r->get('/corpus/:doc_id/:para',
	  [doc_id => qr/\d+/, para => qr/\d+/]
	)->to('Search#snippet')->name('snippet');

  # Store snippets
  $r->post('/corpus/:doc_id/:para',
	   [doc_id => qr/\d+/, para => qr/\d+/]
	 )->to('Collection#store');

  $r->get('/about')->to('about');

  # Catchall
  $self->routes->any('/*catchall', { catchall => '' })->to(
    cb => sub {
      my $c = shift;
      return $c->rabbid_catchall if $multi;
      return $c->reply->not_found;
    });
};


1;


__END__
