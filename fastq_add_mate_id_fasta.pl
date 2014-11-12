#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Add \1 or \2 mate ID to end of read ID (created for Pocket Mouse
#           data) as specified and print to stdout.
# Author:	mdb
# Created:	1/9/12
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "perl fastq_add_mate_id.pl <fastq file> <1|2>" if (@ARGV < 2);

my $INPUT_FILE = $ARGV[0];
my $MATE_NUM = $ARGV[1];

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open input file '$INPUT_FILE'\n");
	
while (my $line = <$inf>) {
	if ($line =~ /^\@(\S+)\s+\S+/) { # header
		my $seq   = <$inf>;
		my $line3 = <$inf>;
		my $qual  = <$inf>;
			
		print "\>$1\\$MATE_NUM\n$seq";
	}
	else {
		die;
	}
}
	
close($inf);

exit;

#-------------------------------------------------------------------------------
