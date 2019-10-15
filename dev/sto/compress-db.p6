#!/usr/bin/env perl6

use DB::SQLite;

# follow procedures found at sqlite.org to
# delete unwanted columns in a table:

=begin comment

(11) How do I add or delete columns from an existing table in SQLite.

SQLite has limited ALTER TABLE support that you can use to add a
column to the end of a table or to change the name of a table. If you
want to make more complex changes in the structure of a table, you
will have to recreate the table. You can save existing data to a
temporary table, drop the old table, create the new table, then copy
the data back in from the temporary table.

For example, suppose you have a table named "t1" with columns names
"a", "b", and "c" and that you want to delete column "c" from this
table. The following steps illustrate how this could be done:

BEGIN TRANSACTION;
CREATE TEMPORARY TABLE t1_backup(a,b);

INSERT INTO t1_backup SELECT a,b FROM t1;

DROP TABLE t1;

CREATE TABLE t1(a,b);

INSERT INTO t1 SELECT a,b FROM t1_backup;

DROP TABLE t1_backup;
COMMIT;

=end comment

# the queries (do one table at a time
my ($tbl, $cols-to-keep);
=begin comment
$tbl = 'ssl_stats';
$cols-to-keep =
<
  mygnus,
  usafa,
  www_usafa_1965_org
>;
=end comment
#=begin comment
$tbl = 'total_stats';
$cols-to-keep = <
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
CREATE TEMPORARY TABLE {$tbl}_backup (
    {$cols-to-keep}
);
INSERT INTO {$tbl}_backup SELECT
    {$cols-to-keep}
FROM {$tbl};
DROP TABLE {$tbl};
CREATE TABLE {$tbl} (
    {$cols-to-keep}
);
INSERT INTO {$tbl}
SELECT
    {$cols-to-keep}
FROM {$tbl}_backup;
DROP TABLE {$tbl}_backup;
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
