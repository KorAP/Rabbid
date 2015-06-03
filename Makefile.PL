use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
    'Mojolicious' => '6.11',
    'Excel::Writer::XLSX' => 0,
    'Mojolicious::Plugin::ReplyTable' => 0
  },
  test      => {TESTS => 't/*.t'}
);
