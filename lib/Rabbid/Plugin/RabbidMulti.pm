package Rabbid::Plugin::RabbidMulti;
use Mojo::Base 'Mojolicious::Plugin';

# Create a plugin that mimics the following behaviour
sub register {
  my ($self, $app) = @_;

  # Catchall helper - called for all nonmatching routes
  unless ($app->renderer->helpers->{rabbid_catchall}) {
    $app->helper(
      rabbid_catchall => sub {
	return shift->reply->not_found;
      }
    );
  };

  # Route shortcut - established before all
  # routes are established
  unless ($app->routes->shortcuts->{rabbid_multi}) {
    $app->routes->add_shortcut(
      rabbid_multi => sub {
	return shift;
      }
    );
  };

  # Return fake account handler
  unless ($app->renderer->helpers->{rabbid_acct}) {
    $app->helper(
      rabbid_acct => sub {
	state $acct = Rabbid::Plugin::RabbidMulti::Acct->new;
      }
    );
  };
};

# Fake account handler class
package Rabbid::Plugin::RabbidMulti::Acct;
use Mojo::Base -base;

has id => 1;
has handle => 'Unknown';


1;


__END__

=pod

Navigation links may be added using the rabbid_navi-helper.
This should happen on app start - not per controller.

  $app->rabbid_navi(
    b('<a href="/logout">Logout</a>')
  );
