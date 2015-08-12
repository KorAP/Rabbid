#!/usr/bin/env
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use lib '../lib', 'lib';

my $t = Test::Mojo->new('Rabbid');
$t->get_ok('/')
  ->status_is(200)
  ->content_is('');
