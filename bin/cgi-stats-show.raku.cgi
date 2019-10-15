#!/usr/local/rakudo.d/bin/perl6

my $default-dbf = './cgi-stats.sqlite';
my $dbf = %*ENV<CGI_STATS_DBF> // $default-dbf;

use CGI::Stats;
show-stats $dbf;
