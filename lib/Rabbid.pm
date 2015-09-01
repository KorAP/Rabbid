package Rabbid;
use Mojo::Base 'Mojolicious';


our $VERSION = '0.3.1';

# This method will run once at server start
sub startup {
  my $self = shift;

  # 120 seconds inactivity allowed
  $ENV{MOJO_INACTIVITY_TIMEOUT} = 120;

  # The secret should be changed!
  $self->secrets(
    ['jgfhnvfnhghGFHGfvnhrvtukrKoGUjhu6464cvrj764cc64ethzvf']
  );

  push @{$self->commands->namespaces}, __PACKAGE__ . '::Command';
  push @{$self->plugins->namespaces},  __PACKAGE__ . '::Plugin';

  # korap.ids-mannheim.de specific path prefixing
  $self->hook(
    before_dispatch => sub {
      my $c = shift;
      my $host = $c->req->headers->header('X-Forwarded-Host');
      if ($host && $host eq 'korap.ids-mannheim.de') {

	# Set Rabbid path and correct host and port information
	my $base = $c->req->url->base;
	$base->path('/rabbid/');
	$base->host($host);
	$base->port(undef);

	# Prefix is used for static assets
	$c->stash(prefix => '/rabbid');
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
  $self->plugin('Config');
  $self->plugin('Notifications');
  $self->plugin('CHI');
  $self->plugin('RenderFile');
  $self->plugin('ReplyTable');
  $self->plugin('TagHelpers::Pagination');
  $self->plugin('Oro');
  $self->plugin('Oro::Viewer');
  $self->plugin('RabbidHelpers');
  $self->plugin('MailException' => {
    from    => join('@', qw/diewald ids-mannheim.de/),
    to      => join('@', qw/diewald ids-mannheim.de/),
    subject => 'Rabbid crashed!'
  });

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
  $r->get('/')->to('Collection#index', collection => 1)->name('collections');
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
