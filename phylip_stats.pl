#!/usr/bin/env perl
#
# Prints statistics for the given phylip file.  
#
# Matt 10/3/10
# -----------------------------------------------------------------------------

use warnings;
use strict;
use POSIX; # for LONG_MAX

die "Usage:  phylip_stats.pl [-s] <input_filename>\n" if ($#ARGV+1 < 1);

my $OPTIONS;
if ($ARGV[0] eq '-s') {
	$OPTIONS = '-s';	# -s for summary only
	shift @ARGV;
}
my $INF = shift @ARGV;  	# input file name 

my $numSections = 0;
my $totalSize = 0;  # all bases (incl. N's)
my $totalNs = 0;
my ($minSecSize, $maxSecSize) = (LONG_MAX, 0);

open INF,"<$INF" or die "Can't open file: $INF\n";
while (<INF>) {
    chomp;
    
    if (/^(\w+)\s+(\w+)/) { # Start of new section
    	$numSections++;
    	
        my $secName = $1;
        my $seq = $2;

        my $secSize = length $seq;
        $minSecSize = $secSize if ($secSize < $minSecSize);
        $maxSecSize = $secSize if ($secSize > $maxSecSize);
        $totalSize += $secSize;
        
        my $n = () = $seq =~ /N/g;
        $totalNs += $n;
        
		print "$secName\t$secSize\n" if (not $OPTIONS or $OPTIONS !~ /-s/);
		#print "$seq\n";
    }
}
close INF;

print "Num sections:  $numSections\n";
print "Total size:    $totalSize (" . ($totalSize-$totalNs) . " non-N's)\n";
print "Min sec size:  $minSecSize\n";
print "Max sec size:  $maxSecSize\n";
print "Avg sec size:  " . ($totalSize/$numSections) . "\n";
