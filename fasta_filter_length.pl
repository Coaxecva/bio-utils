#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Filter input FASTA file(s) based on sequence length.
# Author:	mdb
# Created:	2/17/14
#------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_filter_length.pl <file> <length>\n" if ($#ARGV+1 < 2);

my $INPUT_FILE = shift @ARGV;
my $MIN_LENGTH = shift @ARGV;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $name;
my $seq;
my $line;
while ($line = <INF>) {
    if ($line =~ /^\>(.*)/) {
    	if (defined $seq and length $seq > $MIN_LENGTH) {
    	    print ">$name\n$seq";
    	}
    	
    	$name = $1;
    	$seq = '';
    }
    else {
		$seq .= $line;
    }
}
close(INF);

# Do last one
if (defined $seq and length $seq > $MIN_LENGTH) {
    print ">$name\n$seq";
}

exit;