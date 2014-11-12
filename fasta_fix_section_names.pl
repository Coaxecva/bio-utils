#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/26/13
#------------------------------------------------------------------------------

use warnings;
use strict;
$| = 1;

die "Usage:  fasta_fix_section_names.pl <file>\n" if (@ARGV < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
while (<INF>) {
    if (/^\>/) {
    	chomp;
		(undef, undef, undef, my $name) = split('\|', $_); # for chicken genome from McCarthy lab
		print ">$name\n";
    }
    else {
    	print $_;
    }
}
close(INF);

exit;

#-------------------------------------------------------------------------------
