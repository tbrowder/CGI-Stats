#!/usr/bin/env perl6

use lib '.';

use SQLite-BU;

my $force   = 0;
my $dbf-out = './dbf-bu.sqlite';

if !@*ARGS {
    print qq:to/HERE/;
    Usage: $*PROGRAM <dbf to backup>

    Backs up input SQLite db file to:
        $dbf-out
    HERE
    exit;
}

my $dbf-in;
for @*ARGS {
    when /^f/ { $force = 1 }
    default { $dbf-in = $_}
}

die "FATAL: Input eq output!" if $dbf-in eq $dbf-out;

if $dbf-out.IO.e && !$force {
    say "FATAL: Output file '$dbf-out' exists.";
    say "       Move it or use the 'force' option.";
    exit;
}

# from the used module
backup-sqlite-dbf :$dbf-in, :$dbf-out;

say "Normal end.";
say "See backup dbf: $dbf-out";
 
