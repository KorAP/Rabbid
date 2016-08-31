package Rabbid::Convert::Base;
use Mojo::Base -strict;
use Scalar::Util qw/blessed/;
use Mojo::Util qw!xml_escape!;

# Constructor
sub new {
  my $class = shift;
  my %param = @_;
  # Accept: input, output, log, id_offset
  bless \%param, $class;
};


# Log object
sub log {
  my $self = shift;
  state $log = $self->{log} // Mojo::Log->new;
};

sub version { '0.0' };

# Get RabbidML prologue
sub get_prologue {
  my $self = shift;
  my $hash = shift;

  unless (exists $hash->{doc_id}) {
    $self->log->warn('No doc_id set in ' . $self->{input});
    return;
  };

  my $title = xml_escape(delete($hash->{title}) // ('Unknown ' . $hash->{doc_id}));

  my $string =<<PROLOG;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
PROLOG
  $string .= '    <title>' . $title . "</title>\n";

  if ($hash->{comment}) {
    $string .= '  <!-- ' . _uncomment(xml_escape($hash->{comment})) . " -->\n";
  };

  foreach (keys %$hash) {
    next if $_ eq 'title' || $_ eq 'comment';
    $string .= '    <meta name="' . $_ . '"';
    if (ref $hash->{$_} eq 'ARRAY') {
      $string .= ' content="' . xml_escape(join(' ', @{$hash->{$_}})) . '" />' . "\n";
    }
    else {
      $string .= ' content="' . xml_escape($hash->{$_}) . '" />' . "\n";
    };
  };

  $string .= '    <meta name="generator" ' .
    'content="' . blessed($self) . ' ' . $self->version . '" />' . "\n";

  return $string . "  </head>\n  <body>\n    <h1>" . $title . "</h1>\n";
};


# Get RabbidML epilogue
sub get_epilogue {
  my $self = shift;
  my $comment = shift;
  if ($comment) {
    $comment = "  <!--\n" . _uncomment(xml_escape($comment)) . "\n  -->\n";
  };
  return "  </body>\n" . ($comment // '') . '</html>';
};

sub _uncomment {
  $_[0] =~ s/--/\&#151;/g;
  $_[0];
};

1;
