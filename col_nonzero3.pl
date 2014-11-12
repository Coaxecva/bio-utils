#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print count of non-zero values for specified 3 columns.
# Author:	mdb
# Created:	4/28/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input filename
my $COL = $ARGV[1]; 		# first column number, starting at 0
my $SKIP_LINES = $ARGV[2];	# optional number of header lines to skip
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_nonzero3.pl <input_filename> <column_num> [skip_lines]\n" if ($#ARGV+1 < 2);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $lineNum = 0;

# Skip header
while (defined $SKIP_LINES and $SKIP_LINES--) {
	$lineNum++;
	<INF>;
}

my $count = 0;
while (<INF>) {
	$lineNum++;
	chomp;
	my @tok = split(/$DELIMITER/);
	my $val1 = $tok[$COL];
	my $val2 = $tok[$COL+1];
	my $val3 = $tok[$COL+2];
	die "Error: column $COL doesn't exist in file on line $lineNum\n" if (not defined $val1 or not defined $val2 or not defined $val3);
	$count++ if ($val1 > 0 or $val2 > 0 or $val3 > 0);
}

close(INF);

print "Count: $count\n";

exit;

