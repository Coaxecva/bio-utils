#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Randomly select specified percentage of input reads and save 
# 			to output file called "subset.fastq".
# Usage:	perl randsel.pl <input_file> <percentage>
# Author:	mdb
# Created:	8/27/10
#-------------------------------------------------------------------------------
my $INPUT_FILE  = $ARGV[0];			# FASTQ file
my $OUTPUT_FILE = "subset.fastq";
my $READ_PCT    = $ARGV[1];			# Percentage of reads to select randomly
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage: randsel.pl <input_file> <percentage>\n" if ($#ARGV+1 < 2);

open(OF, ">", $OUTPUT_FILE) or 
	die("Error: cannot open file '$OUTPUT_FILE'\n");

open(F, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $count = 0;
my $line;
while( $line = <F> ){
	if ($line =~ /^\@/) {
		if (rand(1) <= $READ_PCT) {
			$count++;
			print OF $line;
			$line = <F>; print OF $line;
			$line = <F>; print OF $line;
			$line = <F>; print OF $line;
		}
		else {
			# Skip rest of FASTQ record
			<F>;
			<F>;
			<F>;
		}
	}
}
close(F);
close(OF);

print "Selected: $count\n";
exit;

#-------------------------------------------------------------------------------


