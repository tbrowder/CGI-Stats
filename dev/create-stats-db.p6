#!/usr/bin/env perl6

use DB::SQLite;

# Create the tables for the new web stats db
# NOTE: the unique constraint acts as the
#   index for each table.
CREATE TABLE IF NOT EXISTS ssl_stats (
    email    TEXT NOT NULL,
    datehour TEXT NOT NULL,
    -- vhosts INT NOT NULL DEFAULT 0,
    UNIQUE (email, datehour)
);
CREATE TABLE IF NOT EXISTS total_stats (
    ipname   TEXT NOT NULL,
    datehour TEXT NOT NULL,
    -- vhosts INT NOT NULL DEFAULT 0,
    UNIQUE (ipname, datehour)
);


my ($tbl, $cols);
=begin comment
$tbl = 'ssl_stats';
$cols =
<
  mygnus,
  usafa,
  www_usafa_1965_org
>;
=end comment
#=begin comment
$tbl = 'total_stats';
$cols = <
  computertechnwf,
  computertechnwf_org_,
  freestatesus,
  highlandsprings,
  mbrowder,
  mbrowder_com_,
  mygnus,
  nicevillepm,
  novco1968tbs,
  novco1968tbs_com_,
  nwfinfo,
  nwflorida_info_,
  nwflug,
  nwflug_org_,
  nwfpug_nwflorida_info,
  nwfpug_nwflorida_info_,
  owa_novco1968tbs_com,
  owa_usafa_1965_org,
  perl6_app,
  perl6_club,
  psrr,
  psrr_info_,
  santamap_net,
  secure_novco1968tbs_com,
  secure_usafa_1965_org,
  ssl_novco1968tbs_com,
  ssl_usafa_1965_org,
  tombrowder_com,
  usafa,
  usafa_1965_org_,
  www_computertechnwf_org,
  www_computertechnwf_org_,
  www_highlandsprings61_org,
  www_mbrowder_com,
  www_mbrowder_com_,
  www_novco1968tbs_com,
  www_novco1968tbs_com_,
  www_nwflorida_info,
  www_nwflorida_info_,
  www_nwflug_org,
  www_nwflug_org_,
  www_nwfpug_nwflorida_info,
  www_nwfpug_nwflorida_info_,
  www_perl6_app,
  www_perl6_club,
  www_psrr_info,
  www_psrr_info_,
  www_santamap_net,
  www_usafa_1965_org,
  www_usafa_1965_org_
>;
#=end comment

my $qstring = qq:to/HERE/;
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS {$tbl} (
    {$cols-to-keep}
);
COMMIT;
HERE

if !@*ARGS {
    print qq:to/HERE/;
    Usage: $*PROGRAM -go <sqlite3 db> | -show # query string

    Drops unwanted columns in the input dbf.
    HERE
    exit;
}

my $dbf;
my $go   = 0;
my $show = 0;
for @*ARGS {
    when /^'-g'/ { $go   = 1  }
    when /^'-s'/ { $show = 1  }
    default      { $dbf  = $_ }
}

if $show {
    say "The SQL to be executed:\n";
    say $qstring;
    exit;
}

if !$go {
    say "No execution without entering '-go'.";
    exit;
}

say "Dropping unwanted columns in dbf '$dbf'...";

# get the db handle
my $s = DB::SQLite.new: :filename($dbf);

$s.execute: $qstring;
$s.finish;

say "Normal end.";
say "See revised dbf: $dbf";

=finish
# ssl_stats non-zero columns to keep:
  mygnus,
  usafa,
  www_usafa_1965_org

# total_stats non-zero columns to keep:
  computertechnwf,
  computertechnwf_org_,
  freestatesus,
  highlandsprings,
  mbrowder,
  mbrowder_com_,
  mygnus,
  nicevillepm,
  novco1968tbs,
  novco1968tbs_com_,
  nwfinfo,
  nwflorida_info_,
  nwflug,
  nwflug_org_,
  nwfpug_nwflorida_info,
  nwfpug_nwflorida_info_,
  owa_novco1968tbs_com,
  owa_usafa_1965_org,
  perl6_app,
  perl6_club,
  psrr,
  psrr_info_,
  santamap_net,
  secure_novco1968tbs_com,
  secure_usafa_1965_org,
  ssl_novco1968tbs_com,
  ssl_usafa_1965_org,
  tombrowder_com,
  usafa,
  usafa_1965_org_,
  www_computertechnwf_org,
  www_computertechnwf_org_,
  www_highlandsprings61_org,
  www_mbrowder_com,
  www_mbrowder_com_,
  www_novco1968tbs_com,
  www_novco1968tbs_com_,
  www_nwflorida_info,
  www_nwflorida_info_,
  www_nwflug_org,
  www_nwflug_org_,
  www_nwfpug_nwflorida_info,
  www_nwfpug_nwflorida_info_,
  www_perl6_app,
  www_perl6_club,
  www_psrr_info,
  www_psrr_info_,
  www_santamap_net,
  www_usafa_1965_org,
  www_usafa_1965_org_
