#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use lib '../lib', 'lib';
use Rael::Analyzer;
use Mojolicious::Lite;
use File::Temp 'tempdir';

my $tdir = tempdir();

my $t = Test::Mojo->new;
$self->plugin(
  Search => {
    engine => 'Lucy',
    path => $tempdir . '/index',
    schema => {
      content => {
	type => 'fulltext',
	highlightable => 0,
	stored => 0
      }
    }
  },
#  on_init => sub {
#    my $engine = shift;
#    my $app = $engine->controller->app;
#    $app->log->info('Initial indexing');
#    my $path = $app->home . '/sample';
#
#    unless (opendir(SAMPLE, $path)) {
#      fail("Unable to open $path");
#      return;
#    };

);

get '/' => sub {
%= search highlight => 'content', begin
  <head><title><%= search->query %></title></head>
  <body>
<p>Hits: <span id="totalResults"><%= search->total_results %></span></p>
%=   search_results begin
<div>
  <h1><a href="<%= $_->{url} %>"><%= $_->{title} %></a></h1>
  <p class="excerpt"><%= search->snippet %></p>
  <p class="score"><%= $_->get_score %></p>
</div>
%   end
  </body>
% end

};

done_testing;
