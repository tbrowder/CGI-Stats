#!/usr/local/rakudo.d/bin/perl6

use CGI::Stats;

my $default-dbf = './cgi-stats.sqlite';
my $dbf = %*ENV<CGI_STATS_DBF> // $default-dbf;

my $debug = @*ARGS.elems ?? 1 !! 0;
update-stats $dbf, $debug;
