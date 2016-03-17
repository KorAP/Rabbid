package Rabbid::Controller::Document;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::ByteStream 'b';
use IO::File;
require Rabbid::Analyzer;

# my $left_offset = 100;
# my $right_offset = 100;


# This action will render a template
sub overview {
  my $c = shift;

  # Show all docs sorted
  my $corpus = $c->stash('corpus');
  my $cache_handle = 'default';

  # corpus environment
  if ($corpus && ($corpus = $c->config('Corpora')->{$corpus})) {
    $cache_handle = $corpus->{cache_handle};
  };

  # TODO: Make this configurable
  my $oro_table = {
    table => 'Doc',
    cache => {
      chi => $c->chi($cache_handle),
      expires_in => '60min'
    },
    display => [
      'ID' => 'doc_id',
      'Verfasser' => 'author',
      'Titel' =>
	['title', process => sub {
	   my ($c, $row) = @_;

	   return $row->{title} unless $row->{file};

	   return $c->link_to(
	     $c->url_for('file', file => $row->{file}),
	     class => 'file', sub {
	       b('<span>file</span>')
	     }
	   ) . ' ' . ($row->{title} || $row->{file} || '-');
	 }],
      'Jahr' =>
	['year', class => 'integer', process => sub {
	   my ($c, $row) = @_;
	   return $c->filter_by(year => $row->{year});
	 }],
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
