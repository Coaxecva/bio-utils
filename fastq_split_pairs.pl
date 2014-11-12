#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	12/7/11
#-------------------------------------------------------------------------------

use warnings;
use strict;

my @files;
if (@ARGV >= 1) {
	push @files, @ARGV;
}
else {
	@files = <*.fastq>;
}

foreach my $file (@files) {
	open(my $inf, $file) or 
		die("Error: cannot open input file '$file'\n");
	
	my ($prefix) = $file =~ /(\S+)\.fastq/;
	my $outputFile1 = $prefix . '.mate1.fastq';
	my $outputFile2 = $prefix . '.mate2.fastq';
	
	open(my $outf1, '>', $outputFile1) or 
		die("Error: cannot open output file '$outputFile1'\n");

	open(my $outf2, '>', $outputFile2) or 
		die("Error: cannot open output file '$outputFile2'\n");
	
	while (my $line1 = <$inf>) {
	    if ($line1 =~ /^\@(\S+)\s((\d):\S+)/) { # header
	    	print "$1 $2 $3\n"; exit;
	    	my $mate  = $1;
			my $seq   = <$inf>;
		    my $line3 = <$inf>;
		    my $qual  = <$inf>;
			
			if ($mate eq '1') {
				print $outf1 ">$line1$seq$line3$qual";
			}
			elsif ($mate eq '2') {
				print $outf2 ">$line1$seq$line3$qual";
			}
			else {
				die;
			}
	    }
	    else {
	    	die;
	    }
	}
	
	close($inf);
	close($outf1);
	close($outf2);
}

exit;

#-------------------------------------------------------------------------------
