use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Rabbid',
  VERSION_FROM => 'lib/Rabbid.pm',
  ABSTRACT => 'Recherche- und Analyse-Basis für Belegstellen in Diskursen',
  AUTHOR => 'Nils Diewald',
  LICENSE => 'bsd_2',
  PREREQ_PM => {
    'Mojolicious' => '6.11',
    'Mojolicious::Plugin::ReplyTable' => 0,
    'Mojolicious::Plugin::Notifications' => 0,
    'Mojolicious::Plugin::CHI' => 0,
    'Mojolicious::Plugin::Oro' => 0,
    'Mojolicious::Plugin::TagHelpers::Pagination' => 0,
    'Mojolicious::Plugin::Localize' => 0,

    # Temporary
    'Mojolicious::Plugin::Oro::Account' => 0,
    'Mojolicious::Plugin::Oro::Account::ConfirmMail' => 0,
    'Mojolicious::Plugin::Mail' => 0,

    'Mojolicious::Plugin::Oro::Viewer' => 0,
    'Cache::FastMmap' => 0,
    'Excel::Writer::XLSX' => 0,
    'Search::Tokenizer' => 0,
    'Lingua::Stem::UniNE::DE' => 0,
    'DBIx::Oro' => '0.31',
    'Text::FromAny' => 0,
    'Unicode::Normalize' => 0,
    'Encode' => 0,
    'Getopt::Long' => 0
  },
  test => {
    TESTS => 't/*.t'
  }
);
