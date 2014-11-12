#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Filter input FASTA file(s) based on sequence length.
# Author:	mdb
# Created:	12/7/11
#------------------------------------------------------------------------------
my $MIN_LENGTH = 64;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_filter_length.pl <file1> [file2 file3 ...]\n" if ($#ARGV+1 < 1);

while (@ARGV) {
	my $INPUT_FILE = shift @ARGV;
	open(INF, $INPUT_FILE) or 
		die("Error: cannot open file '$INPUT_FILE'\n");
		
	my $name;
	my $line;
	while ($line = <INF>) {
		chomp $line;
	    if ($line =~ /^\>(.*)/) {
	    	$name = $1;
	    }
	    else {
			print ">$name\n$line\n" if (length $line >= $MIN_LENGTH);
	    }
	}
	close(INF);
}

exit;

#-------------------------------------------------------------------------------
