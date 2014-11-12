#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print non-missing values for specified column.
# Author:	mdb
# Created:	4/28/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input filename
my $COL = $ARGV[1]; 		# column number, starting at 0
my $SKIP_LINES = $ARGV[2];	# optional number of header lines to skip
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_nonzero.pl <input_filename> <column_num> [skip_lines]\n" if ($#ARGV+1 < 2);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $lineNum = 0;

# Skip header
#while (defined $SKIP_LINES and $SKIP_LINES--) {
#	$lineNum++;
#	<INF>;
#}

while (my $line = <INF>) {
	if (defined $SKIP_LINES and $lineNum++ < $SKIP_LINES) {
		print $line;
		next;
	}
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	die "Error: column $COL doesn't exist in file on line $lineNum\n" if (not defined $val);
	print "$line\n" if ($val ne '');
}

close(INF);

exit;

