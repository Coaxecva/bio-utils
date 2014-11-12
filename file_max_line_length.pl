#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Find longest line in file.
# Author:	mdb
# Created:	3/15/12
#------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  file_max_line_length.pl <file>\n" if ($#ARGV+1 < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $max = 0;
while (my $line = <INF>) {
	chomp $line;
	$max = length($line) if (length($line) > $max);
}
close(INF);

print "Longest line:  $max\n";

exit;

#-------------------------------------------------------------------------------
