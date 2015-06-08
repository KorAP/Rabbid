package Rabbid::Command::build_db;
use Mojo::Base 'Mojolicious::Command';
use utf8;
use Mojo::DOM;
use Mojo::ByteStream 'b';
use Mojo::Collection 'c';
use Unicode::Normalize qw/NFKC/;
use Text::FromAny;
use Encode;
use Rabbid::Analyzer;

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Initialize Rabbid database.';
has usage       => sub { shift->extract_usage };

sub _init {
  my $db_file = shift;

  # Create database
  return DBIx::Oro->new(
    $db_file => sub {
      my $oro = shift;

      # Create document table
      $oro->do(<<'SQL') or return -1;
CREATE TABLE Doc (
  doc_id  INTEGER PRIMARY KEY,
  author  TEXT,
  year    INTEGER,
  title   TEXT,
  domain  TEXT,
  genre   TEXT,
  polDir  TEXT,
  file    TEXT
)
SQL

      # Create paragraph table
      # local_id is numerical to ensure the next/previous paragraph can be retrieved.
      # use with: SELECT * FROM Paragraph WHERE content MATCH '"der Aufbruch"';
      $oro->do(<<'FTS') or return -1;
CREATE VIRTUAL TABLE Text USING fts4 (
 in_doc_id, para, content, tokenize=perl 'Rabbid::Analyzer::tokenize'
)
FTS

      foreach (qw/doc_id genre polDir domain year/) {
	$oro->do(<<"SQL") or return -1;
CREATE INDEX IF NOT EXISTS ${_}_i ON Doc ($_)
SQL
      };
    });
};

sub _read_doc {
  my $file = shift;
  my $t = Text::FromAny->new(file => $file);

  return unless $t;

  my $text = $t->text;
  return unless $text;

  $text = NFKC($text);
  $text =~ tr!\t! !;
  $text =~ s/^[\n\s\t]*\d+[\n\s\t]*$//mg;
  $text =~ s!!!g;  # Worttrenner
  $text =~ tr!­!!d;  # Worttrenner
  $text =~ s!\s\s+! !g;

  return $text;
};


# Long paragraphs need to be split further
sub _further_split {
  my $full_p = shift;

  return $full_p if length($full_p) < 2000;

  my @lines = ();

  # The paragraph is still too long
  while (length($full_p) > 1200) {

    # Get the start
    my $clean_p = substr($full_p, 0, 1000, '');

    # Try to split at sentence positions
    if ($full_p =~ s/^(.{0,300}?[\?\!\.\:]["']?)\s+([A-ZÖÜÄ])/$2/) {
      push @lines, $clean_p . $1 . '~~~';
    }

    # Try to split at comma
    elsif ($full_p =~ s/^(.{0,300}?,)\s+//) {
      push @lines, $clean_p . $1 . '~~~';
    }

    # Try to split at space
    elsif ($full_p =~ s/^(.{0,300}?)\s+//) {
      push @lines, $clean_p . $1 . '~~~';
    }

    # Well - who damn cares?!
    else {
      push @lines, $clean_p . '~~~';
    };
  };

  # There is a rest left
  push @lines, $full_p if $full_p;

  return c(@lines);
};


# Run command
sub run {
  my $self = shift;

  local $|;
  $|++;

  my $app = $self->app;

  # Get HTML index file
  my $index_file = shift || $app->home . '/db/index.htm';
  my $db_file    = shift || $app->home . '/db/rabbid.sqlite';

  unlink $db_file if -e $db_file;

  print "Index $index_file to $db_file\n";

  # Load HTML file containing document descriptions
  my $dom = Mojo::DOM->new;
  $dom->parse(b($index_file)->slurp->decode);

  # Retrieve and normalize column names
  my @columns;
  $dom->find('th')->each(
    sub {
      my $n = $_->text or return;
      $n =~ s/Nr\./no/;
      $n =~ s!Verfasser/in!author!;
      $n =~ s!Jahr!year!;
      $n =~ s!Titel!title!;
      $n =~ s!^Dom.*$!domain!;
      $n =~ s!Textsorte!genre!;
      $n =~ s!Politische Richtung!polDir!;
      $n =~ s!Dateiname!file!;
      $n =~ s!^Dok.*$!doc_id!;
      push @columns, $n;
    }
  );

  # Retrieve and normalize all document descriptions
  my @docs;
  $dom->find('tr')->each(
    sub {
      my $cells = $_->find('td');
      return if $cells->size == 0;

      my %doc;
      foreach (0 .. $#columns) {
	$doc{$columns[$_]} = $cells->[$_]->all_text if $cells->[$_];
      };

      # Deleted documents - ignore!
      foreach (qw/385 1245 839 1068 843 845 846 1454/) {
	return if $doc{doc_id} == $_;
      };

      delete $doc{no};
      # There are some spelling errors in the source files ...
      $doc{domain} =~ s/^Frau$/Frauen/;
      $doc{domain} =~ s/^Poitik$/Politik/;
      $doc{domain} =~ s/^Zionismus$/Zionisten/;
      $doc{domain} =~ s/^Intell?e?ktuellendiskurs$/Intellektuellendiskurs/;
      $doc{polDir} =~ s/konserativ$/konservativ/;
      $doc{genre}  =~ s/^Zeitungsbericht$/Zeitungsartikel/;


      # Todo: Maybe normalize
      # Artikel? -> Zeitungsartikel?
      # Diskussionsbeiträge -> Stellungnahme?
      # Erklärung? -> Proklamation?
      # Memoiren, Verhör
      # Mann%20Zur%20Feier%20der%20Verfassung.rtf -> 1994?
      push(@docs, \%doc);
    }
  );

  my $oro = _init($db_file);

  # Populate doc table
  $oro->txn(
    sub {
      $oro->insert(Doc => $_) foreach @docs;
    }
  );

  my $doc_i = 0;
  # Populate content table
  foreach (@docs) {
    my $file = $app->home . '/public/corpus/raw/' . $_->{file};
    if (-e $file) {

      # Create casted doc id
      my $docid = 'CAST(' . $_->{doc_id} . ' AS INTEGER)';

      # Retrieve text from document
      my $text = _read_doc($file);

      warn "No text " . $file unless $text;

      print ++$doc_i . ". Parse " . $file, " - ";

      $oro->txn(
	sub {
	  my $oro = shift;

	  # Mark the final paragraph
	  $text =~ s/[\n\s\t]+$//;
	  $text .= '###';

	  my $para = 0;
	  b($text)
	    ->split('[\s\n\t]*\n+[\s\n\t]*')
	      ->map(\&_further_split)
		->flatten->each(
		  sub {
		    return unless $_;
		    print $para, ',';
		    my $para_pos = 'CAST(' . $para++ . ' AS INTEGER)';
		    # Insert Document
		    $oro->insert(Text => {
		      in_doc_id => \$docid,
		      para => \$para_pos,
		      content => $_
		    }) or return -1;
		  });
	});
      print "\n";
    }
    else {
      print "Not found " . b($_->{file})->encode . "\n";
    };
  };
};


1;


__END__

=pod

=head1 SYNOPSIS

  $ perl script/rabbid build_db
