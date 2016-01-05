#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Remove sequence ID from line 3 of FASTQ record.  For cases where
#           ID on line 3 doesn't match ID on line 1, causing a tool such as
#           cutadapt to fail.
# Author:	mdb
# Created:	1/5/16
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "perl fastq_blank_id.pl <fastq file>" if (@ARGV < 1);

my $INPUT_FILE = $ARGV[0];

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open input file '$INPUT_FILE'\n");
	
while (my $line = <$inf>) {
	if ($line =~ /^\@(\S+)/) { # header
		my $seq   = <$inf>;
		my $line3 = <$inf>;
		my $qual  = <$inf>;
			
		print "\@$1\n$seq+\n$qual";
	}
	else {
		die;
	}
}
	
close($inf);

exit;

#-------------------------------------------------------------------------------
