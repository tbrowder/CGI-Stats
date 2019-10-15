#!/usr/bin/env perl6

use Data::Dumper;
use DB::SQLite;

use Data::Random qw(rand_enum rand_chars);

use lib('.');
use WEB_SQLite3_funcs (':all');
use WEB_dbi_funcs (':all');
use WEB_general_funcs qw(:all);

my $error = 0;
my $debug = 0;
# get user's IP
my $sip = '10.0.132.204';
my $sipname = defined $ip ? get_ipname($ip) : 'unknown';

my $dbf = 'test-sqlite.sqlite';
my $debug = shift @ARGV;
$debug = 0 if !defined $debug;

if (!$debug) {
  unlink $dbf;
}

my $dbh = get_database_handle($dbf);
if (!$dbh) {
  print STDERR "       \$dbh is null\n";
  ++$error;
}
die "ERROR exit.\n" if $error;

if ($debug) {
  print "DEBUG: known environment variabless:\n";
  foreach my $k (sort keys %ENV) {
    print "  $k\n";
  }
  die "debug exit";

  print STDERR "debug: \$ip         = '$ip'\n";
  print STDERR "       \$ipname     = '$ipname'\n";
  print STDERR "       \$site       = '$site'\n";
  print STDERR "       \$vhost      = '$vhost'\n";
  print STDERR "       \$dbf        = '$dbf'\n";
  exit;
}

#print "Your IP address (IPA)  : $ip\n";
my $reps = 50;
foreach my $rep (1..$reps) {
  my ($ip, $site, $datestring) = get_random_values();
  if ($rep % 2) {
    # odd number
    ($ip, $site, $datestring) = get_random_values();
  }
  else {
    # even number
    ($ip, $site, $datestring) = get_random_values();
    # use the same IP and site
    $ip = $sip;
    $site = 'bogus.com';
  }
  my $ipname   = get_ipname($ip);
  my $vcolname = get_vhost_colname($site);

  update_stats($dbh, $ipname, $datestring, $vcolname, 'ip');

  # get IP stats
  my $ip_stats_table  = get_tablename('ip');
  my $this_ip_stats   = get_two_column_sum($dbh, $ip_stats_table, $vcolname, $ipname, 'ip');
  my $uniq_ip_stats   = get_two_column_count($dbh, $ip_stats_table, $vcolname, 'ip');
  $uniq_ip_stats     -= 1;
  my $total_ip_stats  = get_column_sum($dbh, $ip_stats_table, $vcolname);

  say <<"HERE";
======================================
Your IP address (IPA)  : $ip
Your site              : $vcolname
Your IPA visits        : $this_ip_stats
Other unique IPA visits: $uniq_ip_stats
Total visits           : $total_ip_stats
HERE
}

if ($debug) {
  say <<'HERE';
=========================
DEBUG: dumping all tables
=========================
HERE
  dump_all_tables($dbh);
}

my $h = get_vhost_hashref();
say Dumper($h);

### subroutines ###
sub get_random_values {
  my @ips
    = (
       '10.0.0.1',
       '193.2.124.3',
       '5.5.6.7',
       '1.2.3.4',
       '100.100.200.50',
      );

  my @sites
    = (
       'highlandsprings61.org',
       'value-mantech.com',
       'mygnus.com',
       'stevegriner.com',
       'usafa-1965.org',

       'psrr.info',
      );

  my @dates
    = (
       # note three unique dates
       '2011000901',
       '2011000901',
       '2011000902',
       '2011000903',
       '2011000903',
      );

  # get three random elements, one from each array
  #my $i = rand_enum(set => \@ips);
  my $i = get_random_ip();
  my $s = rand_enum(set => \@sites);
  #my $d = rand_enum(set => \@dates);
  my $d = get_random_date(set => \@dates);
  return ($i, $s, $d)
}

sub get_random_ip {
  my $ip = '';
  for my $i (0..3) {
    my @n = rand_chars(set => 'numeric', min => 1, max => 3);
    my $n = join('', @n);
    my $s = sprintf "%d", $n;
    $ip .= '.' if $i;
    $ip .= $s;
  }

  #die "debug: ip = '$ip'";
  return $ip;
}

sub get_random_date {
  my @n = rand_chars(set => 'numeric', size => 10);
  my $n = join('', @n);
  my $s = sprintf "%d", $n;

  #die "debug: date = '$s'";
  return $s;
}
