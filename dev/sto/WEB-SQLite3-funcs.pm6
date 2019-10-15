unit module WEB_SQLite3_funcs;

use DBIish;

# the access stats database file (it may be in a special directory)
my $_dbf  = '../data-cmn/domain-access-stats.sqlite';
# the default backup db
my $_bfil = "{$_dbf}.backup";

sub get_database_filename() is export {
  return $_dbf;
} # get_database_filename

sub get_database_handle($dbf) is export {
  # put the database in the same directory with this script and it
  # will be accessed okay, but now using an environment variable

  # provision for another db file
  $_dbf = $dbf if $dbf;
  # note that the absence of a file is not a show stopper!

  my $_dbh = DBIish.connect("dbi:SQLite:dbname=$_dbf",
			  "", # username
			  "", # password
			  {
			   RaiseError => 1,
			   PrintError => 0,
			   AutoCommit => 0, # requires $dbh->commit() after changes to db (do)
			  }
			 );
  $_dbh.do("PRAGMA foreign_keys = ON");
  $_dbh.commit;
  #$_dbh->{AutoCommit} = 1;

  return $_dbh;
} # get_database_handle

sub backup_db($dbh, $bfil) is export {
  $bfil = $bfil ?? $bfil !! $_bfil;

  $dbh.sqlite_backup_to_file($bfil);

} # backup_db
