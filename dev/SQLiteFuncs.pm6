unit module SQLiteFuncs;

use DB::SQLite;

sub add-column(:$dbh, :$table, :$col) is export {
    die "fix this";
}

sub two-row-vals-exist(:$dbh, :$table, :$col1, :$val1, :$col2, :$val2) is export {
    my @a = $dbh.query(qq:to/HERE/, $val1, $val2).arrays;
        SELECT $col1, $col2 FROM $table
        WHERE $col1 = ?, $col2 = ?;
    HERE

    return @a.elems ?? 1 !! 0;
}

sub column-exists(:$dbh, :$table, :$col) is export {
    my %h = $dbh.query(qq:to/HERE/).hash;
        SELECT *, ROWID FROM $table
        WHERE ROWID = 1;
    HERE

    return %h{$col}:exists ?? 1 !! 0;
}

sub backup-sqlite-dbf(:$dbf-in, :$dbf-out) is export {
    # We use Perl 5's DBI to hot-backup an SQLite db file.
    # requires Inline::Perl5
    use DBI:from<Perl5>;

    # get a handle to the desired SQLite db file
    # to be copied
    my $dbh = DBI.connect("dbi:SQLite:dbname=$dbf-in");

    # execute the backup
    $dbh.sqlite_backup_to_file($dbf-out);

    # don't forget to release the handle
    $dbh.disconnect;
}
 

