#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Remove blank entries from FASTA file, print to stdout.
# Author:	mdb
# Created:	1/12/11
#------------------------------------------------------------------------------

use strict;

die "Usage:  fasta_rmblank.pl <file>\n" if ($#ARGV+1 < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $name;
my $seq;
my $len = 0;
my $line;
while ($line = <INF>) {
    if ($line =~ /^\>(.*)/) {
    	if ($len > 0) {
    		print ">$name\n$seq";
    	}
    	$name = $1;
    	$seq = '';
    	$len = 0;
    }
    else {
		$seq .= $line;
		chomp $line;
		$len += length $line;
    }
}
close(INF);

exit;

#-------------------------------------------------------------------------------
