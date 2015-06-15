package Rabbid;
use Mojo::Base 'Mojolicious';
use Cache::FastMmap;


our $VERSION = '0.2.0';


# 120 seconds inactivity allowed
$ENV{MOJO_INACTIVITY_TIMEOUT} = 120;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secrets(
    ['jgfhnvfnhghGFHGfvnhrvtukrKHGUjhu6464cvrj764cc64ethzvf']
  );

  push @{$self->commands->namespaces}, __PACKAGE__ . '::Command';
  push @{$self->plugins->namespaces},  __PACKAGE__ . '::Plugin';

  # Add richtext format
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
  $self->plugin(MailException => {
    from    => join('@', qw/diewald ids-mannheim.de/),
    to      => join('@', qw/diewald ids-mannheim.de/),
    subject => 'Rabbid crashed!'
  });
  # Temporary - User Management
  $self->plugin('Oro::Account');
  $self->plugin('Oro::Account::ConfirmMail');

  # Router
  my $r = $self->routes;

  # Open routes
  $r->any('/login')->acct('login' => { return_url => 'collections' });
  $r->any('/login/forgotten')->acct('forgotten');
  $r->any('/about')->to(
    cb => sub {
      shift->render(template => 'about', about => 1)
    })->name('about');

  # Restricted routes
  # User management
  my $res = $r->route('/')->over(allowed_for => '@all');
  $res->any('/login/remove')->acct('remove');
  $res->any('/preferences')->acct('preferences');
  $res->any('/logout')->acct('logout');

  # Collections
  $res->get( '/')->to('Collection#index', collection => 1)->name('collections');
  $res->get( '/collection/:coll_id')->to(
    'Collection#collection',
    collection => 1
  )->name('collection');

  # Search
  $res->get( '/search')->to('Search#kwic', search => 1)->name('search');

  # Corpus view
  $res->get( '/corpus')->to('Document#overview', overview => 1)->name('corpus');
  $res->get( '/corpus/raw/:file')->name('file');

  # Ajax responses
  $res->get( '/corpus/:doc_id/:para', [doc_id => qr/\d+/, para => qr/\d+/])->to('Search#snippet')->name('snippet');
  $res->post('/corpus/:doc_id/:para',[doc_id => qr/\d+/, para => qr/\d+/])->to('Collection#store');

  # Catchall for restricted routes
  $r->any('/*catchall', { catchall => '' })->to(
    cb => sub {
      my $c = shift;
      return $c->redirect_to('acct_login') unless $c->allowed_for('@all');
      return $c->reply->not_found;
    });
};


1;


__END__
