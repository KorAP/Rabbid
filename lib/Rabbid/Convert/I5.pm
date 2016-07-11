package Rabbid::Convert::I5;
use strict;
use warnings;
use Mojo::Util 'slurp';
use KorAP::XML::Meta::I5;
use Mojo::DOM;
use XML::Twig;

sub new {
  my $class = shift;
  bless {
    file => shift
  }, $class;
};

sub parse {
  my $self = shift;
  my $twig = XML::Twig->new(
    twig_roots => {
      idsHeader => sub {
	my ($twig, $header) = @_;
	print "---\n";
      },
      idsText => sub {
	my ($twig, $text) = @_;
	print "+++\n";
      }
    }
  );

  $twig->parsefile($self->{file});
};



1;
