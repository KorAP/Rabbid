package Rabbid::Controller::Document;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util qw/html_unescape/;
use Fcntl qw(O_APPEND O_CREAT O_EXCL O_RDONLY O_RDWR SEEK_SET);
use IO::File;
require Rabbid::Analyzer;

my $left_offset = 100;
my $right_offset = 100;


# This action will render a template
sub overview {
  my $c = shift;
  # Show all docs sorted

  my $oro_table = {
    table => 'Doc',
    cache => {
      chi => $c->chi,
      expires_in => '60min'
    },
    display => [
      'ID' => sub {
	my ($c, $row) = @_;
	return $c->link_to(
	  $row->{doc_id} // $row->{dID},
	  $c->url_for('file', file => $row->{file})
	)
      },
      'Verfasser' => 'author',
      'Titel' => 'title',
      'Jahr' => ['year', (class => 'integer')],
      'Spektrum' =>
	['polDir', process => sub {
	   my ($c, $row) = @_;
	   return $c->filter_by(polDir => $row->{polDir});
	 }],
      'Domäne' =>
	['domain', process => sub {
	   my ($c, $row) = @_;
	   return $c->filter_by(domain => $row->{domain});
	 }],
      'Textsorte' =>
	['genre', process => sub {
	   my ($c, $row) = @_;
	   return $c->filter_by(genre => $row->{genre});
	 }]
      ]
  };

  # Render document view with oro table
  $c->render(
    template => 'documents',
    oro_view => $oro_table
  );
};


1;


__END__
