#!/usr/bin/env perl6

# this is intended both for the root user use on the remote web server
# as well as for local testing

use lib <.>;
use WEB_SQLite3_funcs;
use WEB_dbi_funcs;
use WEB_general_funcs;

my $debug  = 0;
my $dump   = 0;
my $backup = 0;
my $bweb   = 0; # used periodically by cron
my $cweb   = 0; # for one-time use remotely
my $force  = 0;
my $test   = 0;
my $getbu  = 0;

my $default_dbf  = 'domain-access-stats.sqlite';
my $default_idir = '../data-cmn';
my $default_odir = '/home/tbrowde/backup-dbs.d';

my $idbf  = q{};
my $odbf  = q{};
my $odbf2 = q{};

sub zero_modes {
  $dump   = 0;
  $backup = 0;
  $bweb   = 0; # use on remote host
  $cweb   = 0; # use on local/remote host
  $test   = 0;
  $getbu  = 0; # use on local host
}

if !@*ARGS {
  say qq:to/HERE/;
Usage: $0 -D | -b | -bweb | -t | -g | -i=IDB [-d -f -o=ODB ]

Modes:

  -D dump db to STDOUT
  -b backup
  -bweb
  -t test
  -g get backup
  -i=IDB

Options:

  -d debug
  -o=ODB
  -f force
HERE
  exit;
}

for @*ARGS -> $arg {
  my $val;;
  my $idx = index $arg, '=';
  if $idx.defined {
    $val = substr $arg, $idx+1;
    $arg = substr $arg, 0, $idx;
  }
  if $arg eq '-d' {
    $debug = 1;
  }
  elsif $arg eq '-D' {
    zero_modes();
    $dump = 1;
  }
  elsif $arg eq '-f' {
    $force = 1;
  }
  elsif $arg eq '-i' {
    $idbf = $val;
  }
  elsif $arg eq '-o' {
    zero_modes();
    $backup = 1;
    $odbf = $val;
  }
  elsif $arg eq '-b' {
    zero_modes();
    $backup = 1;
  }
  elsif $arg eq '-t' {
    zero_modes();
    $test = 1;
  }
  elsif $arg eq '-g' {
    zero_modes();
    $getbu = 1;
  }
  elsif $arg eq '-bweb' {
    zero_modes();
    $bweb = 1;
  }
  elsif $arg eq '-cweb' {
    zero_modes();
    $cweb = 1;
  }
}

if $test {
  test_func();
  say "Exiting after calling test function.";
  exit;
}

if $getbu {
  getbu_func();
  say "Exiting after calling getbu function.";
}

if !$idbf {
  $idbf = "{$default_idir}/{$default_dbf}";
}

if $bweb {
  my $date = get_gmtime_backup();
  $odbf  = "{$default_odir}/timed/{$default_dbf}.backup.{$date}";
  $odbf2 = "{$default_odir}/{$default_dbf}.latest-backup";
  if $odbf2.IO.f {
    unlink $odbf2;
  }
}
elsif $cweb {
  my $date = get_gmtime_backup();
  $odbf  = "{$default_odir}/{$default_dbf}.remote-backup";
  if $odbf.IO.f {
    unlink $odbf;
  }
}
elsif !$dump && !$odbf {
  # backup
  my $date = get_gmtime_backup();
  if !$odbf {
    $odbf  = "{$default_odir}/timed/{$default_dbf}.backup.{$date}";
  }
  else {
    $odbf = "{$idbf}.backup.{$date}";
  }
}

if !$idbf.IO.f {
  die "FATAL:  Input file '$idbf' not found.";
}

if !$dump && $odbf.IO.f {
  if $force {
    say "WARNING:  Overwriting existing file '$odbf'.";
  }
  else {
    say "FATAL:  Output file '$odbf' exists.";
    die "  Move it or use the '-f' option.";
  }
}

if $dump {
  my $dbh = get_database_handle($idbf);
  dump_all_tables($dbh);
  $dbh.disconnect;
  say "Dumping all tables in '$idbf' to STDOUT:";
}
else {
  if $debug {
    say "DEBUG: input : '$idbf'";
    say "       output: '$odbf'"
  }
  my $dbh = get_database_handle($idbf);
  backup_db($dbh, $odbf);
  say "Normal end.";
  say "See new backup file '$odbf'.";
  if $odbf2 {
    backup_db($dbh, $odbf2);
    say "Also see new backup file '$odbf2'.";
  }
}

sub getbu_func() {
    # copies file from de2 server to here; uses the 'backup' function??
    my $remdbdir = 'backup-dbs.d';
    my $remhost  = 'de2';
    my $remdbfil = 'domain-access-stats.sqlite.remote-backup';
    #my $remdbf   = "{$remhost}:{$remdbdir}/{$remdbfil}";
    my $remdbf   = "/home/tbrowde/{$remdbdir}/{$remdbfil}";

    my $locdbdir = '../data-cmn';
    my $locdbfil = 'domain-access-stats.sqlite.latest-backup';
    my $locdbf   = "{$locdbdir}/{$locdbfil}";

    # use ssh to run command 'backup-remote-dbs-on-demand' on dedi2, then scp the desired file to its local place
    shell("ssh tbrowde@dedi2 /home/tbrowde/backup-remote-dbs-on-demand b");
    shell("scp tbrowde@dedi2:{$remdbf} .");

    =begin pod
    # doesn't work (Perl 5 or 6)
    # Gofer example: export DBI_AUTOPROXY="dbi:Gofer:transport=stream;url=ssh:user@example.com"
    my $original_dsn  = "dbi:SQLite:dbname='$remdbf'";
    my $transport = 'stream;url=ssh:tbrowde@142.54.186.2'; # de2
    #  my $dbh = get_database_handle($remdbf);
    my $dbh  = DBI.connect("DBD::Gofer::Transport=$transport;...;dsn='$original_dsn'",
			   '','',{RaiseError => 1,PrintError => 1,});
    #  my $dbh = get_database_handle($remdbf);
    $dbh.sqlite_backup_to_file($locdbf);
    $dbh.dispose;
    =end pod

} # getbu_func

sub test_func() {

    my $dbf = '../data-cmn/domain-access-stats.sqlite';
  my $dbh = get_database_handle($dbf);

  my $site  = 'usafa-1965.org';
  my $ip    = '68.117.40.46';
  my $email = 'tom.browder@gmail.com';

  #=== from 'show-site-statistics.cgi ===
  # translate IP address as an IP name (stringified)
  my $ipname = defined $ip ?? get_ipname($ip) !! 'unknown';
  my $vhostcolname = get_vhost_colname($site);
  say "DEBUG: \$vhostcolname = '$vhostcolname'";
  # put a link back to the home page
  # all sites have this file two dirs deep
  my $referer = '../../index.html';

  # get IP stats
  my $ip_stats_table  = get_tablename('ip');
  #my $this_ip_stats   = get_two_column_sum($dbh, $ip_stats_table, $vhostcolname, $ipname, 'ip');
  #my $uniq_ip_stats   = get_two_column_count($dbh, $ip_stats_table, $vhostcolname, 'ip');
  #my $total_ip_stats  = get_column_sum($dbh, $ip_stats_table, $vhostcolname);


  # all visits to this site by this IP
  my $this_ip_stats = get_column_metrics(dbh        => $dbh,
					 tablename  => $ip_stats_table,
					 tgtcolname => $vhostcolname,
					 keycol     => 'ipname',
					 keypred    => "= '$ipname'",
					 metric     => 'sum',
      );
  # all visits to this site by unique IP's
  my $uniq_ip_stats = get_column_metrics(dbh        => $dbh,
					 tablename  => $ip_stats_table,
					 tgtcolname => 'ipname',
					 keycol     => $vhostcolname,
					 keypred    => '> 0',
					 metric     => 'count', # distinct
      );
  if $uniq_ip_stats {
    # don't count this IP
    $uniq_ip_stats  -= 1;
  }

  # all visits to this site by all IP's
  my $total_ip_stats = get_column_metrics(dbh        => $dbh,
					  tablename  => $ip_stats_table,
					  tgtcolname => $vhostcolname,
					  metric     => 'sum',
      );

  my $first_ip_visit = get_ordered_subset(dbh        => $dbh,
					  tablename  => $ip_stats_table,
					  keycol     => 'ipname',
					  keypred    => "= '$ipname'",
					  key2col    => $vhostcolname,
					  key2pred   => '> 0',
					  order      => 'DESC', # ascending
					  tgtcolname => 'datehour',
      );
  my $last_ip_visit = get_ordered_subset(dbh        => $dbh,
					 tablename  => $ip_stats_table,
					 keycol     => 'ipname',
					 keypred    => "= '$ipname'",
					 key2col    => $vhostcolname,
					 key2pred   => '> 0',
					 order      => 'ASC', # ascending
					 tgtcolname => 'datehour',
      );

=begin pod

    # email from SSL client cert
    my $email = $ENV{SSL_CLIENT_S_DN_Email};
  $email = 0 if !defined $email;

=end pod

  # get ssl email stats, if any
  my ($email_stats_table,$this_email_stats, $uniq_email_stats,
      $total_email_stats, $first_email_visit, $last_email_visit);

  if $email {
    $email_stats_table  = get_tablename('email');

    #$this_email_stats   = get_two_column_sum($dbh, $email_stats_table, $vhostcolname, $email, 'email');
    #$uniq_email_stats   = get_two_column_count($dbh, $email_stats_table, $vhostcolname, 'email');
    #$uniq_email_stats  -= 1;
    #$total_email_stats  = get_column_sum($dbh, $email_stats_table, $vhostcolname);

    # all visits to this site by this EMAIL
    $this_email_stats = get_column_metrics(dbh        => $dbh,
					    tablename  => $email_stats_table,
					    tgtcolname => $vhostcolname,
					    keycol     => 'email',
					    keypred    => "= '$email'",
					    metric     => 'sum',
					   );
    # all visits to this site by unique EMAIL's
    $uniq_email_stats = get_column_metrics(dbh        => $dbh,
					    tablename  => $email_stats_table,
					    tgtcolname => 'email',
					    keycol     => $vhostcolname,
					    keypred    => '> 0',
					    metric     => 'count', # distinct
					   );
    if $uniq_email_stats {
      # don't count this EMAIL
      $uniq_email_stats  -= 1;
    }

    # all visits to this site by all EMAIL's
    $total_email_stats = get_column_metrics(dbh        => $dbh,
					     tablename  => $email_stats_table,
					     tgtcolname => $vhostcolname,
					     metric     => 'sum',
					    );

    # new
    $first_email_visit = get_ordered_subset(dbh        => $dbh,
					     tablename  => $email_stats_table,
					     keycol     => 'email',
					     keypred    => "= '$email'",
					     key2col    => $vhostcolname,
					     key2pred   => '> 0',
					     order      => 'DESC', # ascending
					     tgtcolname => 'datehour',
					    );
    $last_email_visit = get_ordered_subset(dbh        => $dbh,
					    tablename  => $email_stats_table,
					    keycol     => 'email',
					    keypred    => "= '$email'",
					    key2col    => $vhostcolname,
					    key2pred   => '> 0',
					    order      => 'ASC', # ascending
					    tgtcolname => 'datehour',
					   );
  }

  $dbh.dispose;

  # now print the page (in chunks)
  {
    say q:to/HERE/;
Content-type: text/html

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Site Statistics</title>

<style>
  .rightstats {
    text-align: left;
  }
  .num {
    width: auto;
    background: #008000;
    color: #ffffff;
    font-size: 1.0em;
    font-family: 'Arial Black', Gadget, sans-serif;
  }
  .text {
    width: 600px;
  }
</style>

</head>

<body>

<h4><a href="$referer">Site Home</a></h4>

<div id="stats">
  <h4 class="statistics">Site Statistics for &lt;$site&gt;:</h4>
HERE
  }

  if $email {
    say qq:to/HERE/;

  <h3 class="statistics">TLS Statistics:</h3>

  <table class="stats">
    <tr>
      <td class="leftstats">Your TLS certificate e-mail address (TCEMA):</td><td class="rightstats">$email</td>
    </tr>
    <tr>
      <td class="leftstats">Your TCEMA visits:</td><td class="rightstats">$this_email_stats</td>
    </tr>
    <tr>
      <td class="leftstats">Other persons' unique TCEMA visits:</td><td class="rightstats">$uniq_email_stats</td>
    </tr>
    <tr>
      <td class="leftstats">Total TCEMA visits:</td><td class="rightstats">$total_email_stats</td>
    </tr>

    <tr>
      <td class="leftstats">First TCEMA visit:</td><td class="rightstats">$first_email_visit</td>
    </tr>
    <tr>
      <td class="leftstats">Last TCEMA visit:</td><td class="rightstats">$last_email_visit</td>
    </tr>
  </table>

  <!-- a form -->
  <form>
    <p>
      Show
        <select name="choice" size="1">
          <option selected>last</option>
          <option>first</option>
        </select>
        <input type="text" name="num_to_show" value="10" size="1" />
      visit(s).
        <input type="submit" name="submit" value="Submit" size="1" />
    </p>
  </form>


HERE
  }

  # this always gets printed
  {
    say qq:to/HERE/;

  <h3 class="statistics">IP Address Statistics:</h3>

  <table class="stats">
    <tr>
      <td class="leftstats">Your IP address (IPA):</td><td class="rightstats">$ip</td>
    </tr>
    <tr>
      <td class="leftstats">Your IPA visits:</td><td class="rightstats">$this_ip_stats</td>
    </tr>
    <tr>
      <td class="leftstats">Other unique IPA visits:</td><td class="rightstats">$uniq_ip_stats</td>
    </tr>
    <tr>
      <td class="leftstats">Total IPA visits:</td><td class="rightstats">$total_ip_stats</td>
    </tr>


    <tr>
      <td class="leftstats">First IPA visit:</td><td class="rightstats">$first_ip_visit</td>
    </tr>
    <tr>
      <td class="leftstats">Last IPA visit:</td><td class="rightstats">$last_ip_visit</td>
    </tr>

  </table>
HERE
  }

} # test_func
