package Rabbid::Convert::I5;
use strict;
use warnings;
use File::Spec::Functions qw/catdir catfile/;
use XML::Twig;
use KorAP::XML::Meta::I5;
use Mojo::DOM;
use Mojo::Log;
use Mojo::Util qw!slurp xml_escape encode!;

# Constructor
sub new {
  my $class = shift;
  my %param = @_;
  # Accept: input, output, log
  bless \%param, $class;
};


# Convert files from the I5 format
sub convert {
  my $self = shift;
  my $cb = ref $_[0] eq 'CODE' ? shift : undef;
  my ($corpus, $doc, $text);

  my $doc_id = $self->{id_offset} // 1;

  my $log = $self->{log} // Mojo::Log->new;

  my $mdom = Mojo::DOM->new->xml(1);

  # Collect generated files in an array
  my @files = ();

  my $twig = XML::Twig->new(
    output_filter => XML::Twig::encode_convert( 'utf-8'),
    twig_roots => {

      # Parse all headers
      idsHeader => sub {
	my ($twig, $header) = @_;

	# Load dom
	my $dom = $mdom->parse($header->outer_xml);

	my $type = $dom->at('*')->attr('type');
	# If the attribute is "document", the switch is caled "doc"
	$type = $type eq 'document' ? 'doc' : $type;

	# Init meta parser object for I5
	my $meta = KorAP::XML::Meta::I5->new(log => $log);

	# Parse meta information
	$meta->parse($dom, $type);

	# Add corpus meta data
	if ($type eq 'corpus') {
	  $corpus = $meta->to_hash;
	}

	# Add doc meta data
	elsif ($type eq 'doc') {
	  $doc = $meta->to_hash;
	}

	# Add text meta data
	elsif ($type eq 'text') {
	  $text = $meta->to_hash;
	  $text->{doc_id} = $doc_id++;

	  # Add document values
	  foreach (keys %$doc) {
	    $text->{$_} //= $doc->{$_};
	  };

	  # Add corpus values
	  foreach (keys %$corpus) {
	    $text->{$_} //= $corpus->{$_};
	  };
	};
      },

      # Parse all texts
      idsText => sub {
	my ($twig, $data) = @_;

	my $filename = lc $text->{text_sigle};
	$filename =~ tr!/!-!;
	$filename .= '.rabbidml';

	my $new_file = catfile($self->{output}, $filename);

	# Check if file can be opened
	if (open(FILE, '>', $new_file)) {
	  my @sentences = $data->get_xpath(".//s");

	  # Generate RabbidML file
	  print FILE _prologue($text);
	  foreach (@sentences) {
	    print FILE '    <p>' . xml_escape(encode('UTF-8', $_->text)) . "</p>\n";
	  };
	  print FILE _epilogue();

	  $log->debug("File $new_file converted");

	  close(FILE);

	  # Release callback
	  if ($cb) {
	    $cb->($new_file);
	  }

	  # Push to return value
	  else {
	    push @files, $new_file;
	  };
	}
	else {
	  $log->warn('Unable to open ' . $new_file);
	};
      }
    }
  );

  # Parse input file
  $twig->parsefile($self->{input});

  return @files;
};


# Add RabbidML prologue
sub _prologue {
  my $hash = shift;

  my $title = xml_escape(delete($hash->{title}) // ('Unknown ' . $hash->{doc_id}));

  my $string =<<PROLOG;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
PROLOG
  $string .= '    <title>' . $title . "</title>\n";

  foreach (keys %$hash) {
    next if $_ eq 'title';
    $string .= '    <meta name="' . $_ . '"';
    if (ref $hash->{$_} eq 'ARRAY') {
      $string .= ' content="' . xml_escape(join(' ', @{$hash->{$_}})) . '" />' . "\n";
    }
    else {
      $string .= ' content="' . xml_escape($hash->{$_}) . '" />' . "\n";
    };
  };

  return $string . "  </head>\n  <body>\n    <h1>" . $title . "</h1>\n";
};

# Add RabbidML epilogue
sub _epilogue {
  return "  </body>\n</html>";
};

1;
