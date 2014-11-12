#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Prints the unmapped reads to stdout in FASTQ format.
# Author:	mdb
# Created:	1/13/11
#------------------------------------------------------------------------------
my $SAM_INPUT_FILE = $ARGV[0];
my $FASTQ_INPUT_FILE = $ARGV[1];
#-------------------------------------------------------------------------------

use strict;

die "Usage:  sam_get_unmapped.pl <sam file> <fastq file>\n" if ($#ARGV+1 < 2);

#
# Get mapped read IDs from SAM file
#

my $totalReads = 0;
my %reads;

open(INF, $SAM_INPUT_FILE) or 
	die("Error: cannot open file '$SAM_INPUT_FILE'\n");

while (<INF> ) {
    if (/^\@/) { # header
    	next;
    }
    elsif (/^(\S+)\t/) {
    	my $name = $1;
    	$reads{$name}++;
    	$totalReads++;
    }
}
close(INF);

print "BAM total reads:  $totalReads\n";
print "unique reads:     " . (keys %reads) . "\n";

exit;

#
# Extract reads from FASTQ not in BAM file
#

open(INF, $FASTQ_INPUT_FILE) or 
	die("Error: cannot open file '$FASTQ_INPUT_FILE'\n");

while (<INF> ) {
    if (/^\@(\S+)\//) { # header
    	my $seqID = $1;
		my $seq   = <INF>;
	    my $line3 = <INF>;
	    my $qual  = <INF>;

		if (not defined $reads{$seqID}) {
			print '@' . $seqID . "\n" . $seq . $line3 . $qual;
		}
    }
}
close(INF);

exit;

#-------------------------------------------------------------------------------


