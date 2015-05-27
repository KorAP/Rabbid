#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib '..', '../lib', 'lib';
use Rael::Controller::Document;

my $re = \&Rael::Controller::Document::get_kwic_re;

is($re->('der'), qr/#der\$0*(\d+?)-0*(\d+?)["#]/, 'one term');
is($re->('der', 'baum'), qr/#der\$0*(\d+?)-\d{6}#baum\$\d{6}-0*(\d+?)["#]/, 'two terms');
is(
  $re->('der', 'alte', 'baum'),
  qr/#der\$0*(\d+?)-\d{6}#alte\$\d{6}-\d{6}#baum\$\d{6}-0*(\d+?)["#]/,
  'three terms'
);

# Search in
my $gs = \&Rael::Controller::Document::get_snippet;

like($gs->('file/test.html', 0, 1413), qr!^<p id="p000001" .+?</p>$!s, 'First paragraph');
like($gs->('file/test.html', 1413, 1611), qr!^<p id="p000002" .+?</p>$!s, 'Second paragraph');
like($gs->('file/test.html', 1611, 1853), qr!^<p id="p000003" .+?</p>$!s, 'Third paragraph');
like($gs->('file/test.html', 1853, 2123), qr!^<p id="p000004" .+?</p>$!s, 'Fourth paragraph');
like($gs->('file/test.html', 1853, 2123), qr!^<p id="p000004" .+?</p>$!s, 'Fourth paragraph');
like($gs->('file/test.html', 2123, 3304), qr!^<p id="p000005" .+?</p>$!s, 'Fifth paragraph');

# Search in
my $high = \&Rael::Controller::Document::highlight_snippet;

is($high->($gs->('file/test.html', 1853, 2123), $re->('marti', 'voelkel')),
   '<p id="p000004" data-vec="#deutsch$000000-000008#jungenschaft$000009-000021#deutsch$000022-000031#jugendbund$000032-000042#marti$000043-000049#voelkel$000050-000057" data-start="00001853" data-end="00002123">Deutsche Jungenschaft Deutscher Jugendbund <mark>Martin Voelkel</mark></p>',
 'Highlight at the end');

is($high->($gs->('file/test.html', 1853, 2123), $re->('deutsch', 'jungenschaft')),
   '<p id="p000004" data-vec="#deutsch$000000-000008#jungenschaft$000009-000021#deutsch$000022-000031#jugendbund$000032-000042#marti$000043-000049#voelkel$000050-000057" data-start="00001853" data-end="00002123"><mark>Deutsche Jungenschaft</mark> Deutscher Jugendbund Martin Voelkel</p>',
 'Highlight at the beginning');

is($high->($gs->('file/test.html', 1853, 2123), $re->('deutsch')),
   '<p id="p000004" data-vec="#deutsch$000000-000008#jungenschaft$000009-000021#deutsch$000022-000031#jugendbund$000032-000042#marti$000043-000049#voelkel$000050-000057" data-start="00001853" data-end="00002123"><mark>Deutsche</mark> Jungenschaft <mark>Deutscher</mark> Jugendbund Martin Voelkel</p>',
 'Highlight twice');

is($high->($gs->('file/test.html', 1853, 2123), $re->('pardautz')),
   '<p id="p000004" data-vec="#deutsch$000000-000008#jungenschaft$000009-000021#deutsch$000022-000031#jugendbund$000032-000042#marti$000043-000049#voelkel$000050-000057" data-start="00001853" data-end="00002123">Deutsche Jungenschaft Deutscher Jugendbund Martin Voelkel</p>',
 'No highlight');


done_testing;
