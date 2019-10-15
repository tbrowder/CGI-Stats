unit module WEB_general_funcs;

# a collection of functions used for general CGI and other Perl
# programs

#use Carp;
use Net::IP::Lite; #Net::Address;

#use Data::Dumper;
use CGI::Application;
use DateTime::Math; #Date::Calc qw(Add_Delta_DHMS);

# local vars
my $_cgi  = 0;
my $debug = 0;
# regexes for usernames and realms
my $uname_r = rx{^ <[a..zA..Z]>**1 <[a..zA..Z0..9_-]>*};

# hosts of interest (strict)
my %vhost # => colname
= (
    # canonical name (vhost)     # table column name (all '.' and '-' converted to '_', no 'www')
    'computertechnwf.org'     => 'computertechnwf_org',
    #'f-111.org'               => 'f_111_org',
    'freestatesofamerica.org' => 'freestatesofamerica_org',
    'freestatesofamerica.us'  => 'freestatesofamerica_us',
    'highlandsprings61.org'   => 'highlandsprings61_org',
    'mbrowder.com'            => 'mbrowder_com',
    'moody67a.org'            => 'moody67a_org',
    'mygnus.com'              => 'mygnus_com',
    'niceville.pm.org'        => 'niceville_pm_org',
    'novco1968tbs.com'        => 'novco1968tbs_com',
    'nwflorida.info'          => 'nwflorida_info',
    'nwflug.org'              => 'nwflug_org',
    'nwfpug.nwflorida.info'   => 'nwfpug_nwflorida_info',
    'psrr.info'               => 'psrr_info',
    'tbrowder.net'            => 'tbrowder_net',
    'tombrowder.com'          => 'tombrowder_com',
    'usafa-1965.org'          => 'usafa_1965_org',

     # for testing
     #'juvat'                 => 'juvat',
     #'juvat2'                => 'juvat2',
     #'local'                 => 'local'
    );

# should be for both tables
my %colnames = set %vhost.values; # fix syntax

sub get-colnames {
  return sort %colnames.keys;
} # get_colnames

my %vhostcolname = ();

# Note that Date::Calc uses month numbers indexed as [1..12] while
# Time::Local (and all unix time functions) use month numbers indexed
# as [0..11].
my %m = ('jan',  1,
	 'feb',  2,
	 'mar',  3,
	 'apr',  4,
	 'may',  5,
	 'jun',  6,
	 'jul',  7,
	 'aug',  8,
	 'sep',  9,
	 'oct', 10,
	 'nov', 11,
	 'dec', 12,
	);

### subroutines ###
sub is-valid-colname($colname) is export {
    return %colnames{$colname}:exists;
} # is-valid-colname

sub format-count($count is copy, $num_places) is export {

    # may have error condition
    $count = 0 if !defined $count;

    # format with leading zeroes
    $count = sprintf "%0*d", $num_places, $count;

    =begin pod
    # format with commas (see Cookbook Recipe ?)
    my $text = reverse $count;
    $text =~ s{(\d\d\d)(?=\d)(?!\d*\.)}{$1,}g;
    $text = scalar reverse $text;
    #die "count = '$count'; text = '$text'";
    $count = $text;
    =end pod

  return $count;
} # format-count

# soon to be obsolete?:
sub get-ipname($ip) is export {
  # converts an IP address (x.x.x.x) to a string
  # suitable for a database string (IPxxx_xxx_xxx_xxx), e.g.,
  #   1.2.3.4 => IP001_002_003_004
  my @d = split '\.', $ip;
  my $nd = +@d;
  die "ERROR: size of \$IP split on '.' for '$ip' is not  4, it's $nd.\n" if (4 != $nd);
  my $ipn = sprintf "IP%03d_%03d_%03d_%03d", @d[0], @d[1], @d[2], @d[3];
  return $ipn;
} # get-ipname

sub get-ip-string($ipi) is export {
  # converts an IP int address (a 32-bit int) to standard octal form
  # (x.x.x.x)
  #   1234 => 1.2.3.4 # format example only
  my $ipbin = $ipi.base(2); # perl6 routine

  my $ips = ip-bintoip($ipi, 4); # Net::IP::Lite
  return $ips;
} # get-ip-string

sub get-ip-int($ips) is export {
  # converts an IP address (x.x.x.x) to an int
  # suitable for a database, e.g.,
  #   1.2.3.4 => 1002003004
  my $ipbin = ip-iptobin($ips);
  my $ipi = $ipbin.base(10);
  return $ipi;
} # get-ip-int

sub get-ip-int-FROM-ipname($ipn) is export {
  # convert ipname to ip_int, e.g.,
  #   IP001_002_003_004 => 1002003004
  $ipn ~~ s/^ IP//;
  my @d = split '_', $ipn;

  my $ip = join '.', @d;
  my $ipbin = ip-iptobin($ip, 4);
  return $ipbin.base(10);

} # get-ip-int-FROM-ipname

=begin pod
sub get_vhost_regex {
  my $vhost = shift @_;
  return 0 if !exists($vhost{$vhost});
  my $regex = $vhost{$vhost};
} # get_vhost_regex
=end pod

sub get-vhost-hashref {
  return %vhost;
}

sub get-vhosts is export {
  my @vh = sort keys %vhost;
  for @vh -> $k {
    my $colname = %vhost{$k};
    if %vhostcolname{$colname}:exists {
      say "ERROR:  dup colname '$colname' for site '$k'; line " . __LINE__;
    }
    else {
      %vhostcolname{$colname} = 1;
    }
  }

  return @vh;
} # get-vhosts

sub get-vhost-canonical-name($site is copy) {
    # $site is the CGI "HTTP_HOST" value,
    # convert it to a FQDN, strip off any 'www',
    # example incoming:
    #   CGI:
    #        www.highlandsprings61.org
    #        143.54.23.1
    #   Apache access log:
    #        www.highlandsprings61.org
    if $site ~~ m:i/^ www '.' (\S*) $/ {
	$site = ~$0;
    }
    return $site;
}

sub create_virtual_host_colname($site) is export {
  # extract the domain name (e.g., 'mygnus.com', 'usafa-1965.org')
  # fully qualified canonical name, e.g., 'mygnus.com'

  if $debug {
    say "DEBUG: incoming site = '$site'; line: " . __LINE__;
  }

  die "FATAL: \$site not defined";

  my $vhostcolname = q{};
  # it may already be in good form
  if %vhost{$site}:exists {
    $vhostcolname = %vhost{$site};
    say "DEBUG: existing vhost colname is '$vhostcolname'" if $debug;
    return; #  $vhostcolname;
  }

  # otherwise modify it to make a legit vhost colname
  $vhostcolname = $site;
  $vhostcolname ~~ s:i/^ http[s]**0..1 \: [\/]**2 [w]*0..3 [\.]**0..1 //;

=begin pod

  #$s =~ s{\A  [w]{3} }{}xmsi;
  #$s =~ s{\A  [\.] }{}xmsi;

=end pod

  $vhostcolname ~~ s:i/ [\/]**1 $ //;
  $vhostcolname ~~ s:i:g/\-//;
  $vhostcolname ~~ s:i:g/\.//;
  say "DEBUG: \$vhostcolname = '$vhostcolname'; line: " . __LINE__ if $debug;

  if %vhostcolname{$vhostcolname}:exists {
    say "ERROR:  dup colname '$vhostcolname' for site '$site'; line " . __LINE__ if $debug;
  }
  else {
    %vhostcolname{$vhostcolname} = 1;
  }

  # update vhost hash
  %vhost{$site} = $vhostcolname;
  return; # $vhostcolname;

} # create_virtual_host_colname

sub get_vhost_colname($site) is export {
  # given a name of a server host (domain name), convert to the
  # accepted database column name

  return 0 if is_ignored_vhost($site); # exists $ignored_hosts{$vhost};

  my $colname = q{};
  # it may already be in good form
  if  %vhost{$site}:exists {
    $colname = %vhost{$site};
    return $colname;
  }

  # otherwise modify it
  create_virtual_host_colname($site);
  if %vhost{$site}:exists {
    $colname = %vhost{$site};
    return $colname;
  }
  else {
    die "FATAL: should not get here!";
  }
} # get_vhost_colname

sub is_ignored_vhost($vhost) is export {
  return 0 unless %ignored_host{$vhost}:exists;
  return 1;
} # get_ignored_vhost

sub is_known_vhost($vhost) is export {
  return 0 unless %vhost{$vhost}:exists;
  return 1;
} #  is_known_vhost

sub is_valid_user_name($name) is export {
  return $name ~~ m/$uname_r/;
} # is_valid_user_name

sub name_regex_help {
  print q:to/HERE/;
User and realm names should not have spaces, but any
character from the set {[a..zA..Z0..9_-]} is allowed
with the leading character from the restricted set
{[a..zA..Z]}.

Examples of valid names:
  A_3
  b-X_yZ

Examples of invalid names:

  _Agr
  9nyZ
  Abc!

HERE
} # name_regex_help

sub set_cookie($q, $source_cgi) is export {
  # from example 11-4, CGI Programming with Perl, 2e:

  my $server  = $q.server_name;
  my $user_id = unique_id();
  my $cookie  = $q.cookie(-name  => "user_id",
			   -value => $user_id,
			   -path  => $source_cgi
			  );
  print $q.redirect( -url => "http://$server/$source_cgi",
		       -cookie => $cookie );
  exit;
} # set_cookie

sub unique_id {
  # from example 11-3, CGI Programming with Perl, 2e:
  # Use Apache's mod_unique_id if available
  return %*ENV<UNIQUE_ID> if %*ENV<UNIQUE_ID>:exists;

  use Digest::MD5;

  my $md5 = Digest::MD5.new;
  my $remote = %*ENV<REMOTE_ADDR> ~ %*ENV<REMOTE_PORT> || 0;

  # Note this is intended to be unique, and not unguessable
  # It should not be used for generating keys to sensitive data
  my $id = $md5.md5_base64(time, $*PID, $remote);
  $id ~~ tr|+/=|-_.|;  # Make non-word chars URL-friendly
  return $id;
} # unique_id

sub from_gmtime_site_access($gmtime) is export {
  # reformat incoming "yyyymmddhh" to "yyyy-mm-dd; hh00 GMT"
  if $gmtime ~~ m/^ (\d**4) (\d**2) (\d**2) (\d**2) $/ {
    my $t = "{$0}-{$1}-{$2}; {$3}00 GMT";
    return $t;
  }
  else {
    die "FATAL: bad input '$gmtime', expected 'yyyymmddhh'";
  }
} # from_gmtime_site_access

sub get_gmtime_site_access() is export {
    # for tracking site access time in databases
    my $dt = DateTime.now(:timezone(0),
			  formatter =>
				    sprintf "%04d%02d%02d%02d",
			  .year, .month, .day, .hour);
  # format as desired (same as SSI DATE_GMT: %Y%m%d%H (yyyymmddhh)
  return $dt.Str;
} # get_gmtime_site_access

sub get_gmtime_display() is export {
    # format as desired
    my $dt = DateTime.now(:timezone(0),
			  formatter =>
				    sprintf "%04d-%02d-%02d %02d:%02d:%02d GMT",
			  .year, .month, .day, .hour, .minute, .second);
  return $dt.Str;
} # get_gmtime_display

sub get_gmtime_backup() is export {
    # format as desired
    my $dt = DateTime.now(:timezone(0),
			  formatter =>
				    sprintf "%04d-%02d-%02dT%02dh%02dm%02ds-GMT",
			  .year, .month, .day, .hour, .minute, .second);

    return $dt.Str;
} # get_gmtime_backup

# private functions (for now)
sub get_cgi {
  # get a cgi handle
  if !$_cgi {
    $_cgi = CGI.new();
  }
  return $_cgi;
} # get_cgi

sub get_apache_log_datestring($date, $time, $diffgmt) is export {
    # convert a date, time, and UTC offset from an Apache log entry to
    # my own format

    # with Perl 6 it's much easier
    my $intime = "{$date}T{$time}{$diffgmt}";
    my $dt = DateTime.new($intime);
    my $dtsec = $dt.posix;
    my $dthrs = $dtsec div 3600;

    =begin pod
    #my $date    = shift @_; # format "dd/MON/yyyy"
    #my $time    = shift @_; # format "hh:mm:ss"
    #my $diffgmt = shift @_; # format "[+-]hhmm"

    # from Cookbook, Recipe 3.7
    my ($d, $M, $y)      = ($date    ~~ m:i/^ (\d+)    '/' (\D+) '/' (\d+) / );
    my ($h, $min, $sec)  = ($time    ~~ m:i/^ (\d\d)   \:  (\d\d) \: (\d\d) / );
    my ($pm, $dh, $dmin) = ($diffgmt ~~ m:i/^ (<[+-]>) (\d\d) (\d\d) / );

    # convert month name to number
    my $MON = $M.lc;

    # convert deltas to signed numbers
    $pm = 0 if !defined $pm;
    my $DDh   = get_number("$dh");
    my $DDmin = get_number("$dmin");

    # apply the signs if necessary
    if $pm && $pm eq '-' {
	$DDh   *= -1;
	$DDmin *= -1;
    }

    # convert deltas to their negatives for conversion to UTC
    my $Dh   = -1 * $DDh;
    my $Dmin = -1 * $DDmin;
    =end pod

    =begin pod
    # notes
    if (0) {
	print "debug inputs\n";
	print "  inputs\n";
	print "    date    = '$date'\n";
	print "    time    = '$time'\n";
	print "    diffgmt = '$diffgmt'\n";
	print "  outputs\n";
	print "    day     = '$d'\n";
	print "    month   = '$M'\n";
	print "    month   = '$MON'\n";
	#print "    month   = '$m'\n";
	print "    year    = '$y'\n";
	print "    hour    = '$h'\n";
	print "    min     = '$min'\n";
	print "    sec     = '$sec'\n";
	print "    +/-     = '$pm'\n";
	print "    dh      = '$dh'\n";
	print "    dmin    = '$dmin'\n";
	print "    DDh     = '$DDh'\n";
	print "    DDmin   = '$DDmin'\n";
	print "    Dh      = '$Dh'\n";
	print "    Dmin    = '$Dmin'\n";
    }
    =end pod

    =begin pod
    # critical section
    die "??? \$MON = '$MON'...unknown value!" unless %m{$MON}:exists;
    my $m = %m{$MON};

    # using Date::Calc [month number indexed as [1..12]
    my ($YY, $MM, $DD, $hh, $mm, $ss) =
    Add_Delta_DHMS($y, $m, $d, $h, $min, $sec,
		   0, $Dh, $Dmin, 0); # $Dd, $Dh, $Dm, $Ds);

    $ds = sprintf "%04d%02d%02d%02d", $YY, $MM, $DD, $hh;
    =end pod

    =begin pod
    # notes:
    if (0) {
	my $orig = sprintf "%04d%02d%02d%02d", $y, $m, $d, $h;

	print "  after DateTime\n";
	print "    orig    = '$orig'\n";
	print "    final   = '$ds'\n";
	die "debug exit";
    }
    =end pod

    =begin pod
    return $ds;
    =end pod

} # get_apache_log_datestring

sub get_apache_log_epoch_hours($date, $time, $diffgmt) is export {
    # convert a date, time, and UTC offset from an Apache log entry to
    # hours since the Unix epoch

    # with Perl 6 it's much easier
    my $intime = "{$date}T{$time}{$diffgmt}";
    my $dt = DateTime.new($intime);
    my $dtsec = $dt.posix;
    my $dthrs = $dtsec div 3600;

    return $dthrs;

    =begin pod
    #my $date    = shift @_; # format "dd/MON/yyyy"
    #my $time    = shift @_; # format "hh:mm:ss"
    #my $diffgmt = shift @_; # format "[+-]hhmm"

    # from Cookbook, Recipe 3.7
    my ($d, $M, $y)      = ($date    ~~ m:i/^ (\d+) '/' (\D+) '/' (\d+) / );
    my ($h, $min, $sec)  = ($time    ~~ m:i/^ (\d\d) ':' (\d\d) ':' (\d\d) / );
    my ($pm, $dh, $dmin) = ($diffgmt ~~ m:i/^ (<[+-]>) (\d\d) (\d\d) / );

    # convert month name to number
    my $MON = lc $M;

    # convert deltas to signed numbers
    $pm = 0 if !defined $pm;
    my $DDh   = get_number("$dh");
    my $DDmin = get_number("$dmin");

    # apply the signs if necessary
    if $pm && $pm eq '-' {
	$DDh   *= -1;
	$DDmin *= -1;
    }

    # convert deltas to their negatives for conversion to UTC
    my $Dh   = -1 * $DDh;
    my $Dmin = -1 * $DDmin;
    =end pod

    =begin pod
    # notes
    if (0) {
	print "debug inputs\n";
	print "  inputs\n";
	print "    date    = '$date'\n";
	print "    time    = '$time'\n";
	print "    diffgmt = '$diffgmt'\n";
	print "  outputs\n";
	print "    day     = '$d'\n";
	print "    month   = '$M'\n";
	print "    month   = '$MON'\n";
	#print "    month   = '$m'\n";
	print "    year    = '$y'\n";
	print "    hour    = '$h'\n";
	print "    min     = '$min'\n";
	print "    sec     = '$sec'\n";
	print "    +/-     = '$pm'\n";
	print "    dh      = '$dh'\n";
	print "    dmin    = '$dmin'\n";
	print "    DDh     = '$DDh'\n";
	print "    DDmin   = '$DDmin'\n";
	print "    Dh      = '$Dh'\n";
	print "    Dmin    = '$Dmin'\n";
    }
    =end pod

    =begin pod
    my $epoch_hours;
    my ($YY, $MM, $DD, $hh, $mm, $ss);

    # critical section
    die "??? \$MON = '$MON'...unknown value!" unless %m{$MON}:exists;
    my $m = %m{$MON};

    # using Date::Calc [month number indexed as [1..12]
    ($YY, $MM, $DD, $hh, $mm, $ss) =
    Add_Delta_DHMS($y, $m, $d, $h, $min, $sec,
		   0, $Dh, $Dmin, 0); # $Dd, $Dh, $Dm, $Ds);

    # using Time::Local convert back to epoch seconds
    # adjust month index
    my $Month = $MM -1;
    # year is number of years since 1970
    my $Year = $YY - 1970;
    $epoch_hours = timegm($ss, $mm, $hh, $DD, $Month, $Year);

    # convert epoch time in seconds to hours
    $epoch_hours = int($epoch_hours / 3600);
    =end pod

    =begin pod
    # notes
    if (0) {
	my $ds = sprintf "%04d%02d%02d%02d", $YY, $MM, $DD, $hh;
	my $orig = sprintf "%04d%02d%02d%02d", $y, $m, $d, $h;

	print "  after DateTime\n";
	print "    orig        = '$orig'\n";
	print "    final       = '$ds'\n";
	print "    epoch_hours = '$epoch_hours'\n";
	die "debug exit";
    }
    =end pod

    =begin pod
    if $epoch_hours {
	my $ds = sprintf "%04d%02d%02d%02d", $YY, $MM, $DD, $hh;
	my $orig = sprintf "%04d%02d%02d%02d", $y, $m, $d, $h;

	print "  after DateTime\n";
	print "    orig        = '$orig'\n";
	print "    final       = '$ds'\n";
	print "    epoch_hours = '$epoch_hours'\n";
	die "debug exit";
    }

    return $epoch_hours;
    =end pod

} # get_apache_log_epoch_hours

sub get_number($str) is export {
  # converts a string to a number
  # trim leading and trailing white space
  $str .= trim;
  # trim extra leading zeroes
  $str ~~ s/^00/0/;
  return $str.base(10);
} # get_number

# from Perl 5 Date::Calc
sub Add_Delta_DHMS($y, $m, $d, $h, $min, $sec,
		   # $Dd, $Dh, $Dm, $Ds
		   0, $Dh, $Dmin, 0) is export {
    # use Perl 6 DateTime::Math functions

    my $intime = sprintf "%04d-%02d-%02dT%02d:%02d:$02d",
                         $y, $m, $d, $h, $min, $sec;
    my $dt0 = DateTime.new($intime);
    # add the deltas
    my $dt1 = DateTime.clone
} # Add_Delta_DHMS

sub dbi-log($msg, :$file-name) is export {
    my $fh = open $file-name, :w, :a;
    $fh.say: $msg;
    $fh.close;
} # dbi-log
