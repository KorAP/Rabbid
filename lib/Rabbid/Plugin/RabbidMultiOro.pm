package Rabbid::Plugin::RabbidMulti;
use Mojo::Base 'Mojolicious::Plugin';

# Register plugin to establish
# helpers, shortcuts and conditions
# for an extended multi user and multi
# corpora scenario.
# This requires closed source plugins.
sub register {
  my ($plugin, $app) = @_;

  # Add navigation points
  $app->rabbid_navi(
    q!<%= link_to 'acct_preferences', class => 'preferences', title => rabbid_acct->handle,  begin %><span><%= rabbid_acct->handle %></span><% end %>!,
    q!<%= link_to nocsrf_url_for('acct_logout')->query({return_url => signed_url_for(url_for)}), rel => 'logout', class => 'logout', title => 'Abmelden', begin %><span><%= loc('logout') %></span><% end %>!
  );

  # Register User Management
  $app->plugin('Oro::Account');
  $app->plugin('Oro::Account::ConfirmMail');

  # Catchall helper
  $app->helper(
    rabbid_catchall => sub {
      my $c = shift;
      return $c->redirect_to('acct_login') unless $c->allowed_for('@all');
      return $c->reply->not_found;
    }
  );

  $app->routes->add_shortcut(
    rabbid_multi => sub {
      my $r = shift;

      # Open routes for user management
      $r->any('/login')->acct('login' => { return_url => 'collections' });
      $r->any('/login/forgotten')->acct('forgotten');
      $r->any('/about')->to(
	cb => sub {
	  shift->render(template => 'about', about => 1)
	})->name('about');

      # Restricted routes for user management
      my $res = $r->route('/')->over(allowed_for => '@all');
      $res->any('/login/remove')->acct('remove');
      $res->any('/preferences')->acct('preferences');
      $res->any('/logout')->acct('logout');

      return $res->route(
	'/:corpus_id' =>
	  [corpus_id => qr/[-a-zA-Z0-9_]+/ ]
	)->over('corpus_restriction');
    }
  );

  $app->routes->add_condition(
    corpus_restriction => sub {
      my ($r, $c, $captures) = @_;

      my $cid = $captures->{corpus_id};

      # Everybody is allowed to access 'demo'
      return 1 if $cid eq 'demo';

      # Check if the corpus is allowed to be accessed by the user
      my $active = $c->oro_session->active;
      if ($active && $active->is('@' . $cid)) {
	return 1;
      };
      return;
    }
  );
};


1;

__END__
