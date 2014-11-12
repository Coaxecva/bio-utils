#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Calculate the mean of the specified column.
# Author:	mdb
# Created:	5/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input filename
my $COL = $ARGV[1]; 		# column number, starting at 0
my $SKIP_LINES = $ARGV[2];	# optional number of header lines to skip
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_mean.pl <input_filename> <column_num>\n" if (@ARGV < 2);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

while (defined $SKIP_LINES and $SKIP_LINES--) {
	<INF>;
}

my $count = 0;
my $total = 0;
while (<INF>) {
	next if (/^#/);
	chomp;
	my @tok = split /\t/;
	my $val = $tok[$COL];
	next if (not defined $val or $val eq '');
	$total += $val;
	$count++;
}

close(INF);

print "Count: $count\n";
print "Mean:  " . ($total/$count) . "\n";

exit;

