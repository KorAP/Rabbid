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
    'Mojolicious::Plugin::ReplyTable' => 0.04,
    'Mojolicious::Plugin::RenderFile' => 0,
    'Mojolicious::Plugin::Notifications' => 0.9,
    'Mojolicious::Plugin::MailException' => 0.19,
    'Mojolicious::Plugin::CHI' => 0.11,
    'Mojolicious::Plugin::TagHelpers::Pagination' => 0.06,

    'DBIx::Oro' => 0.31_3, # GitHub
    'Mojolicious::Plugin::Oro' => 0.06, # GitHub
    'Mojolicious::Plugin::Localize' => 0.09, # GitHub

    'Mojolicious::Plugin::Oro::Viewer' => 0,
    'Cache::FastMmap' => 1.40,
    'Excel::Writer::XLSX' => 0.84,
    'RTF::Writer' => 0,
    'Search::Tokenizer' => 1.01,
    'Lingua::Stem::UniNE::DE' => 0.08,
    'Text::FromAny' => 0,
    'Unicode::Normalize' => 1.18,
    'Encode' => 2.73,
    'Getopt::Long' => 0
  },
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  META_MERGE => {
    recommends => {
      # IDS specific sources for user management
      # These are closed source
      'Mojolicious::Plugin::Oro::Account' => 0.22,
      'Mojolicious::Plugin::Oro::Account::ConfirmMail' => 0.06,
      'Mojolicious::Plugin::Mail' => 1.5
    }
  },
  test => {
    TESTS => 't/*.t'
  }
);
