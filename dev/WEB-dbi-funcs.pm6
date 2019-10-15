unit module WEB_dbi_funcs;

# a collection of functions used for DBI and CGI programs

# local vars
my $debug = 0;
my $dbg   = 0;
if $debug {
    say "DEBUG: file 'WEB_dbi_funcs.pm'";
}

# the table for total IP stats
my $_t_ip_table = 'total_stats'; # was $_ttable
# the table for total TLS email stats
my $_t_email_table = 'email_stats';

my %table-type = %(
    'ip'
    => {
        key-col   => 'ipname',
        key2-col  => 'datehour',
        tablename => $_t_ip_table,
    },
    'email'
        => {
        key-col   => 'email',
        key2-col  => 'datehour',
        tablename => $_t_email_table,
    },
);

### subroutines ###
sub update-stats($dbh,
		 $id,       # IP name (xxx.xxx.xxx.xxx => IPxxx_xxx_xxx_xxx)
		            #   or email name
		 $datehour, # input as a datestring (yyyymmddhh)
		 $colname,  # column for domain name
		 $typ,      # 'ip', 'email', 'cookie'
		) is export {

    die "unknown type '$typ'"
    unless %table_type{$typ}:exists;

    =begin pod
    # this may not be needed yet
    if !is_known_vhost($vhost) {
	#die "Unknown vhost '$vhost'"
	# create one
    }
    =end pod

    my $key_col   = %table_type{$typ}<key_col>;
    my $key2_col  = %table_type{$typ}<key2_col>;
    my $tablename = %table_type{$typ}<tablename>;

    my ($s, $statement);

    #==========================================
    # all data are in a single table (one for each type: ip, email, etc.)
    # does the table exist?
    if table_exists($dbh, $tablename) {
	# does the column exist?
	{
	    if !column_exists($dbh, $tablename, $colname) {
		add_column($dbh, $tablename, $colname, 'int', 0);
	    }
	}

	# does the row exist?
	{
	    $s = qq:to/HERE/;
            SELECT $key_col, $key2_col, $colname
	    FROM  $tablename
	    WHERE $tablename.$key_col  = '$id'
	    AND   $tablename.$key2_col = '$datehour';
            HERE
	}

	# untaint
	$statement = _untaint_statement($s);

	if 0 && $debug {
	    say  'debug at line: ' ~ $*IN.ins; #__LINE__;
	    say  "  \$1 : '$1'";
	}

	my ($ip, $thours, $result) = $dbh.selectrow_array($statement);
	$result = $result.defined ?? $result !! -1;

	if $debug {
	    say  'debug at line: ' . __LINE__;
	    chomp $s;
	    chomp $statement;
	    say  "  s        : '$s'";
	    say  "  statement: '$statement'";
	    say  "  hours: $thours result: $result" if $result != -1;
	}

	if $result == -1 {
	    # row does not exist, need an INSERT
	    # insert
	    {
		$s = qq:to/HERE/;
		INSERT INTO $tablename($key_col, $key2_col, $colname)
		VALUES('$id', '$datehour', 1);
		HERE
	    }

	    # untaint it
	    $statement = _untaint_statement($s);

	    if $debug {
		say  'debug at line: ' . __LINE__;
		#say  "  \$1 : '$1'";
		say  "  \$statement : '$statement'";
		say  "  \$s         : '$s'";
	    }

	    my $rows_affected = $dbh.do($statement);
	    $dbh.commit;

	    if $debug {
		say  'debug at line: ' . __LINE__;
		chomp $s;
		chomp $statement;
		say  "  s        : '$s'";
		say  "  statement: '$statement'";
		say  "  rows affected: $rows_affected";
	    }

	    if !defined($rows_affected) || $rows_affected != 1 {
		my $res = defined $rows_affected ?? $rows_affected !! 'undef';
		warn "unexpected rows affected by INSERT: '$res' (should be 1)\n";
	    }
	}
	else {
	    # the same, we can return
	    #warn "this step should NOT happen!\n";
	    # row DOES exist, we MAY need UPDATE, but first check the hours
	    #   if epoch hours, numeric comparison, else alphs
	    my $res = compare_datehours($datehour, $thours);
	    return if $res == 0; # $datehour  <= $thours
	    ++$result;
	    my $rows_affected = $dbh.do(qq{
					       UPDATE $tablename
					       SET $key2_col  = '$datehour',
					       $colname   = '$result'
						WHERE $key_col = '$id';
					   });
	    die "unexpected rows affected by UPDATE: $rows_affected (should be 1)"
	    if $rows_affected != 1;
	    $dbh.commit;
	}
    }
    else {
	# create the table
	my $tname = _create_totals_table($dbh, $typ);
	die "FATAL: '$tablename' ne '$tname'"
	if $tablename ne $tname;

	# insert
	# print "debug: \$colname = '$colname'\n"; die "debug exit";

	# the new table may not have the column yet
	if !column_exists($dbh, $tablename, $colname) {
	    insert_column($dbh, $tablename, $colname, 'int', 0);
	}

	my $rows_affected = $dbh.do(qq{
					   INSERT INTO $tablename($key_col, $key2_col, $colname)
					   VALUES('$id', '$datehour', 1);
				       });
	die "unexpected rows affected by INSERT: $rows_affected (should be 1)"
	if $rows_affected != 1;
	$dbh.commit;
    }
    #die "debug exit";

} # update-stats

sub create-totals-table($dbh, $typ) is export {
  # creates a new totals table according to the desired type

  die "unknown type '$typ'"
    unless %table-type{$typ}:exists;

  my $key-col   = %table-type{$typ}<key_col>;
  my $key2-col  = %table-type{$typ}<key2_col>;
  my $tablename = %table-type{$typ}<tablename>;

  # note that the values for 'epoch_hours' are int(time / 3600) to yield
  # hours since the epoch

  # THIS TABLE MUST MATCH THE COLUMN NAMES FOR %VHOSTS
  # IN MODULE WEB_general_funcs
  # note that a ',' must NOT follow the last column name

  # prepare the statement
  my $statement = "CREATE TABLE IF NOT EXISTS $tablename (\n";
  $statement ~= "$key_col text NOT NULL,\n";
  $statement ~= "$key2_col text NOT NULL,\n";
  my (@keys) = get_vhosts();
  my $nk = @keys;
  loop (my $i = 0; $i < $nk - 1; ++$i) {
    my $colname = get_vhost_colname(@keys[$i]);
    say "DEBUG: colname = '$colname'; line: " . __LINE__ if $debug;
    $statement ~= "$colname int NOT NULL DEFAULT 0,\n";
  }
  # don't forget the last one (no trailing comma)
  my $colname = get_vhost_colname(@keys[$nk-1]);
  say "DEBUG: colname = '$colname'; line: " . __LINE__ if $debug;
  $statement ~= "$colname int NOT NULL DEFAULT 0\n";
  $statement ~= ");\n";
  if $debug {
    say "DEBUG: statement =>; line: " . __LINE__;
    say $statement;
    say "DEBUG: end statement =>; line: " . __LINE__;
  }
  my $sth = $dbh.prepare($statement);
  $sth.execute();

  return $tablename;

=begin pod

  my $sth = $dbh.prepare(qq{
    CREATE TABLE IF NOT EXISTS $tablename
      $key_col        text default 0,
      $key2_col       text default 0,
      highlandsprings int default 0,
      mygnus          int default 0,
      stevegriner     int default 0,
      usafa           int default 0,
      mantech         int default 0,
      unknown         int default 0,
      vh1             int default 0,
      juvat           int default 0
    );
  });
  $sth.execute();

=end pod

} # create-totals-table

sub column_exists($dbh, $tablename, $colname) is export {

  # this is a last recourse and should be general (see "Perl DBI," p. 149)
  my $statement = "SELECT * FROM $tablename";
  my $sth = $dbh.prepare($statement);
  $sth.execute();
  my %vals = $sth.allrows(:hash-of-array);
  my $ncols = %vals<NUM_OF_FIELDS>;
  my @cols = ();
  loop (my $i = 0; $i < $ncols; ++$i) {
    my $cnam = %vals<NAME>[$i];
    if $cnam eq $colname {
      return 1;
    }
  }
  return 0;

=begin pod

  return 0 if !table_exists($dbh, $tablename);
  carp "error exit" if !defined $colname;

  # use PRAGMA table_info($tablename)
  my ($result) = $dbh.selectall_hashref(qq{
    PRAGMA table_info($tablename);
  }, 'name');

  if ($debug && 0) {
    my $res = defined $result ? $result : 'undef';
    printf  "debug at line: %d\n", __LINE__;
    print   "  searching for existence of table '$tablename', column '$colname'\n";
    print   Dumper($result);
    carp "error exit";
  }

  return (exists $result.{$colname});

=end pod

} # column_exists

sub dump_all_tables($dbh) is export {

  # get a list of all user tables
  my $sth = $dbh.prepare(qq{
    SELECT name
    FROM sqlite_master
    WHERE type='table';
  });
  $sth.execute();

  my @tables = ();
  while (my ($tablename) = $sth.fetchrow_array) {
    push @tables: $tablename;
  }

  @tables = (sort @tables);
  for @tables -> $t {
    say "Dumping table '$t':";
    dump_table($dbh, $t);
  }
} # dump_all_tables

sub dump_table($dbh, $tablename) is export {

  return if !table_exists($dbh, $tablename);

  # get all rows
  my $sth = $dbh.prepare(qq{
    SELECT *
    FROM $tablename;
  });
  $sth.execute();
  my $nrows = $sth.dump_results();

} # dump_table

sub table-exists($dbh, $tablename) is export {

  my ($result) = $dbh.selectrow_array(qq{
    SELECT name
    FROM sqlite_master
    WHERE type='table' and name='$tablename';
  });

  if $debug && 0 {
    my $res = defined $result ?? $result !! 'undef';
    printf  "debug at line: %d\n", $*IN.ins; # __LINE__;
    print   "  searching for existence of table '$tablename'\n";
    print   "  result: $res\n";
    #die "debug exit";
  }

  return $result;

} # table_exists

sub compare_datehours($datehour, $thours) is export {
    return ($datehour cmp $thours);
} # compare_datehours

sub get_tablename($typ) is export {
  die "unknown type '$typ'"
    unless %table_type{$typ}:exists;
  my $tablename = %table_type{$typ}<tablename>;
  return $tablename;
} # get_tablename

=begin pod

 # example statements for sub 'get_column_metrics'

 # total (all visits by a single email or IP):
 SELECT SUM(usafa)             # tgtcolumn
 FROM   total_stats            # tablename
 WHERE  ipname = 'IP';         # keycol, keypred

 # unique (number of unique email or IP visitors to this site):
 SELECT COUNT(DISTINCT ipname) # tgtcolumn
 FROM  total_stats             # tablename
 WHERE usafa > 0;              # keycol, keypred

 # total (total visits to a site by all email or IP):
 SELECT SUM(usafa)             # tgtcolumn
 FROM  total_stats;            # tablename


 # end example statements for sub 'get_column_totals'

=end pod

sub get_column_metrics(%h) is export {
  # get a column count of (possibly unique) entries in the key column
  # for > 0 totals in the target column

  my $dbh        = %h<dbh>;
  my $tablename  = %h<tablename>;
  my $tgtcolname = %h<tgtcolname>; # column to be counted
  my $metric     = %h<metric>;     # 'sum' or 'count'

  # these are not required for total visits by all visitors
  my $keycol     = %h<keycol>;
  my $keypred    = %h<keypred>;

  my $err = 0;
  # need the tablename and db handle
  if !$tablename {
    say "ERROR: no table name defined";
    ++$err;
  }
  if !$dbh {
    say "ERROR: no database handle defined";
    ++$err;
  }
  # also the metric
  if !$metric {
    say "ERROR: no metric defined";
    ++$err;
  }
  else {
    $metric = $metric.uc;
  }

  # some defaults
  if $keycol {
    $keypred = '> 0' if !$keypred;
  }

  # if we have a keypred, we need a keycol
  if $keypred && !$keycol {
    say "ERROR: no keycol defined";
    ++$err;
  }
  if $keycol && !$keypred {
    say "ERROR: no key predicate defined";
    ++$err;
  }

  if $metric ne 'SUM' && $metric ne 'COUNT' {
    say "ERROR: metric = '$metric', should be 'SUM' or 'COUNT'";
    ++$err;
  }

  if $err {
    die "FATAL: too many errors";
  }

  #=== CODE ===
  # error checks
  if 0 {
    return 0 if !table_exists($dbh, $tablename);
    return 0 if !column_exists($dbh, $tablename, $tgtcolname);
    return 0 if ($keycol && !column_exists($dbh, $tablename, $keycol));
  }
  else {
    my $err = 0;
    ++$err if !table_exists($dbh, $tablename);
    ++$err if !column_exists($dbh, $tablename, $tgtcolname);
    ++$err if $keycol && !column_exists($dbh, $tablename, $keycol);
    die "FATAL" if $err;
  }

  # build the statement
  my ($result, $statement, $s, $val);
  if $metric eq 'COUNT' {
    $s = "SELECT COUNT(DISTINCT $tgtcolname)";
  }
  else {
    $s = "SELECT SUM($tgtcolname)"
  }
  $s ~= " FROM $tablename";
  if $keycol {
    $s ~= " WHERE $keycol $keypred";
  }
  $s ~= ";";

  #say "=====DEBUG: statement:";
  #say $statement;
  #say "=====end DEBUG: statement:";

  # untaint
  $statement = _untaint_statement($s);

  if 0 {
    return "DEBUG: $statement";
  }

  my $sth = $dbh.prepare($statement);
  # error check
  $err = $dbh.err ?? $dbh.err !! '';
  if 0 && $err {
    return "DEBUG: $err";
  }

  # execute the query
  my $nrows = $sth.execute;

  #if (0 && $err) {
  if $err {
    return "DEBUG: $err";
  }
  my @row = $sth.fetchrow_array;
  $val = join ' ', @row;
  return $val;

=begin pod

  my ($result) = $dbh.selectrow_array(qq{
    SELECT COUNT(DISTINCT $key_col)
    FROM $tablename
    WHERE $tablename.$colname > 0;
  });

  my $count = defined $result ? $result : 0;

  if ($debug && $dbg) {
    $result = defined $result ? $result : 'undef';
    printf  "debug at line: %d\n", __LINE__;
    print   "  calc COUNT column '$colname' in table '$tablename'\n";
    print   "  result: $result\n";
    print   "  count : $count\n";
    die "debug exit";
  }

  return $count;

=end pod

} # get_column_metrics

sub insert_column {
  # inserts a column
  my $dbh       = shift @_;
  my $tablename = shift @_;
  my $colname   = shift @_;
  my $coltyp    = shift @_;
  my $default   = shift @_;

  return 0 if (!table_exists($dbh, $tablename));

  # double check
  return if column_exists($dbh, $tablename, $colname);

  my ($s, $statement);

  $s  = "ALTER TABLE $tablename\n";
  $s ~= "ADD COLUMN $colname $coltyp ";
  if (defined $default) {
    $s ~= "\nNOT NULL DEFAULT $default";
  }
  $s ~= ';';

  # untaint
  $statement = _untaint_identifier($s);

  my $rows_affected = $dbh.do($statement);
  $dbh.commit;

} # insert_column

=begin pod

 # example statements for sub 'get_ordered_subset'

 SELECT MIN(DISTINCT datehour) FROM ssl_stats WHERE
 email = 'tom.browder@gmail.com'
 AND usafa > 0;

 SELECT MAX(DISTINCT datehour) FROM ssl_stats WHERE
 email = 'tom.browder@gmail.com'
 AND usafa > 0;

 SELECT datehour FROM ssl_stats WHERE
 email = 'tom.browder@gmail.com'
 AND usafa > 0
 ORDER BY datehour ASC;

 SELECT datehour FROM ssl_stats WHERE
 email = 'tom.browder@gmail.com'
 AND usafa > 0
 ORDER BY datehour DESC;

 # end example statements for sub 'get_ordered_subset'

=end pod

sub get_ordered_subset(%h) is export {
  # use up to two keys to get a range (or min or max) from a third
  # column

  my $dbh        = %h<dbh>;
  my $tablename  = %h<tablename>;
  my $keycol     = %h<keycol>;
  my $keypred    = %h<keypred>;
  my $tgtcolname = %h<tgtcolname>; # column to be extracted from
  my $order      = %h<order>;      # 'asc' [default] or 'desc'

  # these are not required
  my $key2col    = %h<key2col>;
  my $key2pred   = %h<key2pred>;
  my $numvals    = %h<numvals>;

  # need at least one key;
  my $err = 0;
  if !$keycol {
    say "ERROR: no keys defined";
    ++$err;
  }
  if !$keypred {
    say "ERROR: no key predicate defined";
    ++$err;
  }

  # need the tablename and target column name
  if !$tablename {
    say "ERROR: no table name defined";
    ++$err;
  }
  if !$tgtcolname {
    say "ERROR: no target column name defined";
    ++$err;
  }
  if !$dbh {
    say "ERROR: no database handle defined";
    ++$err;
  }

  # if key2 is defined or key2pred is defined. we must have the other
  if $key2col && !$key2pred {
    say "ERROR: no key2 predicate defined";
    ++$err;
  }
  elsif $key2pred && !$key2col {
    say "ERROR: no key2col defined";
    ++$err;
  }

  # some defaults
  if !$order {
    $order = 'ASC';
  }
  elsif $order ~~ /:i desc/ {
    $order = 'DESC';
  }
  elsif $order ~~ /:i asc/ {
    $order = 'ASC';
  }

  #=== CODE ===
  # error checks
  if 1 {
    return 0 if !table_exists($dbh, $tablename);
    return 0 if !column_exists($dbh, $tablename, $keycol);
    return 0 if !column_exists($dbh, $tablename, $tgtcolname);
    return 0 if (defined $key2col && !column_exists($dbh, $tablename, $key2col));
  }
  else {
    my $err = 0;
    ++$err if !table_exists($dbh, $tablename);
    ++$err if !column_exists($dbh, $tablename, $keycol);
    ++$err if !column_exists($dbh, $tablename, $tgtcolname);
    ++$err if (defined $key2col && !column_exists($dbh, $tablename, $key2col));
    die "FATAL" if $err;
  }

  # build the statement
  my ($result, $statement, $s);
  if ($numvals == 1) {
    my $val;
    # then use min or max function
    if ($order eq 'ASC') {
      # max
      $s  = "SELECT MAX(DISTINCT $tgtcolname)";
      $s ~= " FROM $tablename WHERE";
      $s ~= " $keycol $keypred";
      if (defined $key2col) {
        $s ~= " AND $key2col $key2pred";
      }
    }
    else {
      # min
      $s  = "SELECT MIN(DISTINCT $tgtcolname)";
      $s ~= " FROM $tablename WHERE";
      $s ~= " $keycol $keypred";
      if (defined $key2col) {
        $s ~= " AND $key2col $key2pred";
      }
    }
    $s ~= ";";

    # untaint
    $statement = _untaint_statement($s);

    if (0) {
      return "DEBUG: $statement";
    }

    my $sth = $dbh.prepare($statement);
    # error check
    my $err = $dbh.err ?? $dbh.err !! '';
    if 0 && $err {
      return "DEBUG: $err";
    }

    # execute the query
    my $nrows = $sth.execute;

    #if (0 && $err) {
    if $err {
      return "DEBUG: $err";
    }
    my @row = $sth.fetchrow_array;
    $val = join ' ', @row;
    if $val !~~ /\S/ {
      $val = '(no known visit)';
    }
    else {
      $val = from_gmtime_site_access($val);
    }
    return $val;
  }
  else {
    my $val;
    $s  = "SELECT $tgtcolname";
    $s ~= " FROM $tablename WHERE";
    $s ~= " $keycol $keypred";
    if (defined $key2col) {
      $s ~= " AND $key2col $key2pred";
    }
    $s ~= " ORDER BY $tgtcolname $order;";
    $s ~= ";";

    # untaint
    $statement = _untaint_statement($s);
    my $sth = $dbh.prepare($statement);
    # execute the query
    my $nrows = $sth.execute;
    # error check
    my $err = $dbh.err ?? $dbh.err !! '';
    if $err {
      return $err;
    }

    # return an array (or array ref) on numvals rows
    my @row = $sth.fetchrow_array;
    $val = join ' ', @row;
    if $val ~~ /\s*/ {
      $val = '(unknown)';
    }
    return $val;
  }

} # get_two_column_ordered_subset

sub _untaint_identifier($s is copy) is export {

  # untainting regex
  # match everything BUT:
  my $rx = rx/<-[`\$%^&*+:<>]>+/;

  my $statement;
  # untaint
  if $s ~~ m/^ \s* ($rx) \s* $/ {
    $statement = ~$0;
  }
  else {
    $statement = q{};
  }

  return $statement;

} # _untaint_identifier

sub _untaint_statement($s is copy) is export {

  # untainting regex
  # match everything BUT:
  my $rx = rx/<-[`\$^&*+]>+/;

  my $statement;
  # untaint
  if $s ~~ m/^ \s* ($rx) \s* $/ {
    $statement = ~$0;
  }
  else {
    $statement = q{};
  }

  return $statement;

} # _untaint_statement

sub get_col_min_value($dbh, $tablename, $colname) is export {

  my $table_exists = table_exists($dbh, $tablename);
  return 0 if !$table_exists;

  if $debug && $dbg {
    print  "DEBUG (get_column_count): \n";
    print  "  vcolname  = '$colname'\n";
    print  "  tablename = '$tablename'\n";
  }

  my $col_exists = column_exists($dbh, $tablename, $colname);

  if $debug && $dbg {
    print  "  colname   = '$colname'\n";
    print  "    exists? = '$col_exists'\n";
  }

  return 0 if !$col_exists;

  my $result = $dbh.selectrow_array(qq{
    SELECT MIN(DISTINCT $colname)
    FROM $tablename;
  });

  my $min = $result ?? $result !! '';

  if $debug && $dbg {
    $result = $result ?? $result !! 'undef';
    printf  "debug at line: %d\n", $*IN.ins; # __LINE__;
    print   "  calc COUNT column '$colname' in table '$tablename'\n";
    print   "  result: $result\n";
    print   "  min   : $min\n";
    #die "debug exit";
  }

  return $min;

} # get_col_min_value

sub get_col_max_value($dbh, $tablename, $colname) is export {

  my $table_exists = table_exists($dbh, $tablename);
  return 0 if !$table_exists;

  if ($debug && $dbg) {
    print  "DEBUG (get_column_count): \n";
    print  "  vhost     = '$colname'\n";
    print  "  tablename = '$tablename'\n";
  }

  my $col_exists = column_exists($dbh, $tablename, $colname);

  if $debug && $dbg {
    print  "  colname   = '$colname'\n";
    print  "    exists? = '$col_exists'\n";
  }

  return 0 if !$col_exists;

  my ($result) = $dbh.selectrow_array(qq{
    SELECT MAX(DISTINCT $colname)
    FROM $tablename;
  });

  my $max = $result ?? $result !! '';

  if $debug && $dbg {
    $result = $result ?? $result !! 'undef';
    printf  "debug at line: %d\n", $*IN.ins; # __LINE__
    print   "  calc COUNT column '$colname' in table '$tablename'\n";
    print   "  result: $result\n";
    print   "  max   : $max\n";
    #die "debug exit";
  }

  return $max;

} # get_col_max_value

sub do_sql_no_query($dbh, $statement) is export {

  my $sth   = $dbh.prepare($statement);
  my $nrows = $sth.execute;

  # good result
  return 1;

} # do_sql_no_query

sub do_sql_query($dbh, $statement) is export {

} # do_sql_query
