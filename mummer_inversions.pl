#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	6/12/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $QUERY = 'X';
my $TARGET = 'X';
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

die "Usage:  mummer_inversions.pl <file>\n" if (@ARGV < 1);

my $total = 0;
my $inversions = 0;
my %lengths;

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

while (my $line = <$fh>) {
	chomp $line;
	my @tok = split(/\t/, $line);
	my $start1  = $tok[0];
	my $end1    = $tok[1];
	my $start2  = $tok[2];
	my $end2    = $tok[3];
	my $length1 = $tok[4];
	my $length2 = $tok[5];
	my $pctId   = $tok[6];
	my $qsize   = $tok[9];
	my $tsize   = $tok[10];
	my $qframe	= $tok[11];
	my $tframe	= $tok[12];
	my $qname   = $tok[13];
	my $tname   = $tok[14];
	
	next if (defined $TARGET and defined $QUERY and ($tname ne $TARGET or $qname ne $QUERY));
	
	my $dir1 = ($end1 - $start1 > 0);
	my $dir2 = ($end2 - $start2 > 0);
	
	if ($dir1 != $dir2) {
		#print "$line\n";
		$lengths{($length1+$length2)/2}++;
		$inversions++;
	}
	$total++;
}
close($fh);

print "Total:      $total\n";
print "Inversions: $inversions\n";
print make_histogram2(\%lengths, undef, 100, "-si");

exit;

