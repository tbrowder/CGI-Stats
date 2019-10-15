#!/usr/bin/env perl6

use DB::SQLite;

if !@*ARGS {
    print qq:to/HERE/;
    Usage: $*PROGRAM <SQLite3 dbf OLD format>

    Extracts summary data from the input SQLite3 dbf.
    The input file must have two tables, each with
    three types of columns:

        ssl_stats
            email
            datehour
            vhost1
            ...
            vhostM

        total_stats
            ipname
            datehour
            vhost1
            ...
            vhostN

    The default function checks that each row
    has a unique combination of entries in 
    columns 1 and 2 and, for each unique
    value in column 1, shows the count of
    columns 2, and the sums of the values
    in each vhost column.

    Additionally, vhost columns summing to
    zero are noted so they may be deleted.
    HERE
    exit;
}

my $dbf = shift @*ARGS;

my $s = DB::SQLite.new: :filename($dbf);

my $date = Date.new(now);
my @ofils;

my $t1 = 'ssl_stats';
my $t2 = 'total_stats';

# output files
my $of1 = "{$dbf}.{$t1}.summary";
my $of2 = "{$dbf}.{$t2}.summary";

for $t1, $t2 -> $tbl-nam {

    # save data
    my $last-v1 = '';
    my $last-v2 = '';

    my %chk;    # to ensure unique v1,v2 combos for each row
    my %tot;    # holds totals per v1 per ????
    my %coltot; # holds totals per vhost

    my $c1;
    my $of;
    if $tbl-nam eq $t1 {
        # ssl_stats
        $c1 = 'email';
        $of = $of1;
    }
    elsif $tbl-nam eq $t2 {
        # total_stats
        $c1 = 'ipname';
        $of = $of2;
    }
    my $c2 = 'datehour';

    my $fh = open $of, :w;
    @ofils.append: $of;

    my @ah = $s.query(qq:to/HERE/).hashes;
        SELECT * FROM $tbl-nam
        ORDER BY $c1, $c2
    HERE
    
    for @ah -> %h {
        my $val1 = %h{$c1};
        my $val2 = %h{$c2};
        %h{$c1}:delete;
        %h{$c2}:delete;

        my $u = "{$val1}{$val2}";
        if %chk{$u}:exists {
            note "Unexpected dup val1/val2 pair: '$val1' '$val2'";
        }
        %chk{$u} = 1;

        if !$last-v1 {
            # set values for the new table
            for %h.keys -> $cnam {
                %coltot{$cnam} = 0;
            }
        }
        if $val1 ne $last-v1 {
            # new email or ipname
            # set values for the next c1
            for %h.keys -> $cnam {
                %tot{$val1}{$cnam} = 0;
            }
        }
        $last-v1 = $val1;

        if $val2 ne $last-v2 {
            # new datehour
        }
        $last-v2 = $val2;

        # add to various totals
        for %h.keys -> $cnam {
            my $val = %h{$cnam};
            %coltot{$cnam} += $val;
        }
    }

    # report
    $fh.say: "zero-value columns:";
    for %coltot.keys.sort -> $cnam {
        my $val = %coltot{$cnam};
        next if $val;
        $fh.say: "  $cnam";
    }
    $fh.say: "NON-zero-value columns:";
    for %coltot.keys.sort -> $cnam {
        my $val = %coltot{$cnam};
        next if !$val;
        $fh.say: "  $cnam => $val";
    }

    $fh.close;
}

=finish

#| 2. Print csv of emails without names
multi MAIN(2) {
    # this is good for a sign-in roster
    my $qnum = 2; # MUST match constant sub arg
    my $title = "TBD";
    my $of = "{$date}-{$title}-query-{$qnum}.csv";
    say "Query $qnum is NYI";

    my @ae = $s.query(q:to/HERE/).arrays;
        SELECT email FROM email
        WHERE person_id like '%not%avail%'
        order by email
    HERE

    for @ae -> @e {
        say @e[0];
    }

    # print this on stderr for info only
    note "\nquery got {@ae.elems} nameless emails";
}

#| 3. Generate 'members.source' for the website
multi MAIN(3) {
    my $of = "./public/members.source";

    # prepared queries for reuse
    # get the number of emails by person id
    my $qe = q:to/HERE/;
       SELECT email FROM email
       WHERE person_id = ?
    HERE

    # get years attended by person id
    my $qa = q:to/HERE/;
       SELECT year FROM attend
       WHERE person_id = ?
    HERE

    # get years with presentations by person id
    my $qp = q:to/HERE/;
       SELECT year FROM present
       WHERE person_id = ?
    HERE

    # start with all people
    my @ah = $s.query(q:to/HERE/).hashes;
       SELECT *, rowid AS id FROM person
       ORDER BY key
    HERE

    my $fh = open $of, :w;
    my ($id, $last, $first, $key);

    my $n = 0;
    for @ah -> %h {
        ++$n;
        if $*debug && $n > 10 {
            say "DEBUG: last after 10 people";
            last;
        }

        #$id    = %h<rowid> // '';
        $id    = %h<id>     // '';
        $last  = %h<last>  // '';
        $first = %h<first> // '';
        $key   = %h<key>   // die "FATAL: no key for person rowid $id";

        my @ae = $s.query($qe, $key).arrays;
        say "DEBUG: emails {@ae.elems}" if $*debug;
        for @ae -> @x {
        }

        my @aa = $s.query($qa, $key).hashes;
        say "  attend years {@aa.elems}" if $*debug;
        my %y;
        for @aa -> %x {
            my $y = %x<year>;
            %y{$y} = 0;
        }

        my @ap = $s.query($qp, $key).hashes;
        say "  present years {@ap.elems}" if $*debug;
        for @ap -> %x {
            my $y = %x<year>;
            %y{$y} = 1;
        }

        # assemble the $yr string in reverse order
        my $yr = '';
        for %y.keys.sort.reverse -> $y is copy {
            my $p = %y{$y};
            $y ~= 'p' if $p;
            $yr ~= ' ' if $yr;
            $yr ~= $y;
        }

        $fh.say: "name: $last, $first";
        $fh.say: "id: $id";            # rowid from person table
        $fh.say: "email: {@ae.elems}"; # number of good emails
        $fh.say: "meetings: $yr";      # years attended or presented
        $fh.say: "";
    }

    # print this on stderr for info only
    note "\nquery got {@ah.elems} persons";
    note "See output file '$of'."
}

=finish

#| 4. For a person (oid), what years was the person an attendee or a
#| presenter
multi MAIN(4) {
    my $qnum = 4; # MUST match constant sub arg
    my $title = "TBD";
    my $of = "{$date}-{$title}-query-{$qnum}.csv";
    say "Query $qnum is NYI";
    my $pkey = prompt "Enter person key (see query 6): ";
}

#| 5. A list of all known valid emails for upload to a mail server
multi MAIN(5) {
    my $qnum = 5; # MUST match constant sub arg
    my $title = "TBD";
    my $of = "{$date}-{$title}-query-{$qnum}.csv";

    # we want unique emails (DISTINCT)
    my @e = $s.query("select distinct email from email order by email").arrays;
    say "$_[0]" for @e;

    say "\nquery got {@e.elems} rows";
}

#| 6. List contacts: id last, first
multi MAIN(6) {
    my $qnum = 6; # MUST match constant sub arg
    my $title = "TBD";
    my $of = "{$date}-{$title}-query-{$qnum}.csv";

    my @h = $s.query("select rowid, * from person").hashes;
    for @h -> %h {
        my $id    = %h<rowid>;
        my $key   = %h<key>;
        my $last  = %h<last>;
        my $first = %h<first>;

        say sprintf("%03d $last, $first", $id);
    }
}

END {
   $s.finish if $s;
   #note "Cleaned up dbh and sth.";
}
