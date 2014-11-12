#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Remove blank lines from input FASTA file
# Author:	mdb
# Created:	3/16/12
#------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_remove_blank.pl <file>\n" if ($#ARGV+1 < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
while (my $line = <INF>) {
	if ($line !~ /^\>/) {
		chomp $line;
		next if (length($line) == 0);
		$line .= "\n";
	}
	print $line;
}
close(INF);

exit;

#-------------------------------------------------------------------------------
