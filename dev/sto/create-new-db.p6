#!/usr/bin/env perl6

use DB::SQLite;

# Create the tables for a new db.
# Put the desired sql in the following
# string:
my $schema = qq:to/HERE/;
CREATE TABLE IF NOT EXISTS  (
);
HERE

if !@*ARGS {
    print qq:to/HERE/;
    Usage: $*PROGRAM -go <sqlite3 dbf> | -show # sql string

    Executes sql for the dbf which need not exist.
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
    say $schema;
    exit;
}

if !$go {
    say "No execution without entering '-go'.";
    exit;
}

say "Executing sql in dbf '$dbf'...";

# get the db handle
my $s = DB::SQLite.new: :filename($dbf);

$s.execute: $schema;
$s.finish;

say "Normal end.";
say "See revised or new dbf: $dbf";
