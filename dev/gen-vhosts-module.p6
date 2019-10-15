#!/usr/bin/env perl6

use Text::More :strip-comment;

my $if     = 'domains.summary';
my $mtitle = 'MyVhosts';
my $of     = "{$mtitle}.pm6";

if !@*ARGS {
    print qq:to/HERE/;
    Usage: $*PROGRAM go [force]

    Use file '$if' (from my Namecheap tools)
    to produce module '$of'.
    HERE
    exit;
}

my $go    = 0;
my $force = 0;
for @*ARGS {
    when /^g/ { $go    = 1  }
    when /^f/ { $force = 1  }
}

if !$go {
    say "No execution without entering 'go'.";
    exit;
}

if $of.IO.e && !$force {
    say "FATAL: File '$of' exists.";
    say "       Move it or use the 'force' option'.";
    exit;
}

my %vhosts;
my $max = 0;
for $if.IO.lines -> $line is copy {
    $line = strip-comment $line;
    next if $line !~~ /\S/;
    my @w = $line.words;
    my $vhost = @w.shift;

    my $vcol = $vhost;
    # transform into a legitimate SQL column name
    $vcol ~~ s:g/'.'/_/;
    $vcol ~~ s:g/'-'/_/;

    $vhost = "'$vhost'";
    my $nc = $vhost.chars;
    $max = $nc if $nc > $max;
    %vhosts{$vhost} = $vcol;
}

# pretty print
my $fh = open $of, :w;
$fh.print: qq:to/HERE/;
unit module {$mtitle};

our \%dom-list is export = \%(
HERE

for %vhosts.keys.sort -> $k {
    my $v = %vhosts{$k};
    my $str = sprintf "    %-*s => '$v',", $max, $k;
    $fh.say: $str;
}
$fh.say: ");";
$fh.close;

say "Normal end.";
say "See output file '$of'.";
