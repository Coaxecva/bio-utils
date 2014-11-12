#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	10/11/10
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;


open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $maxLen = 0;
my $mismatches = 0;
my $comparisons = 0;

my $line;
while(not eof(INF)) {
	my @readSeq;
	
	for (1..4) {
    	my $id    = <INF>;  chomp $id;
		my $seq   = <INF>;  chomp $seq;
	    my $line3 = <INF>;  #chomp $line3;
	    my $qual  = <INF>;  chomp $qual;

	    push @readSeq, $seq;
	    $maxLen = length($seq) if (length($seq) > $maxLen);
    }
    
	for (my $i = 0;  $i < $maxLen;  $i++) {
		my $b1 = substr($readSeq[0], $i, 1);
		my $b2 = substr($readSeq[2], $i, 1);
		$mismatches++ if ($b1 ne $b2);
		$comparisons++;
	}
	# Subtract out known SNP
	$mismatches--;
	$comparisons--;
}
close(INF);

print "mismatches: $mismatches (" . sprintf("%.2f", 100*$mismatches/$comparisons) . "%)\n";

exit;

#-------------------------------------------------------------------------------
