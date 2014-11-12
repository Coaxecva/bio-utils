#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Filter input FASTA file(s) based on section name
# Author:	mdb
# Created:	3/15/12
#------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_remove_NT.pl <file>\n" if ($#ARGV+1 < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $name;
while (my $line = <INF>) {
    if ($line =~ /^\>\s*(\S+)/) {
    	$name = $1;
    }
    if (defined $name and $name !~ /^NT/) {
    	print $line;	
    }
}
close(INF);

exit;

#-------------------------------------------------------------------------------
