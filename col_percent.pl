#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print top and/or bottom % values for specified column.
# Author:	mdb
# Created:	4/28/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input filename
my $COL = $ARGV[1]; 		# column number, starting at 0
my $SKIP_LINES = $ARGV[2];	# optional number of header lines to skip
my $TOP_OR_BOTTOM = 'bottom';
my $PERCENT = 0.05;
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_percent.pl <input_filename> <column_num> [skip_lines]\n" if ($#ARGV+1 < 2);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
my $lineNum = 0;
my @vals;
while (my $line = <INF>) {
	if (defined $SKIP_LINES and $lineNum++ < $SKIP_LINES) {
		#print $line;
		next;
	}
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	if (defined $val and $val ne '' and $val =~ /[-+]?[0-9]*\.?[0-9]+/) {
		push @vals, $val;
	}
}
close(INF);

@vals = sort {$a<=>$b} @vals;
my $bottom = $vals[int(@vals * $PERCENT)];
my $top = $vals[int(1 - @vals * $PERCENT)];

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
$lineNum = 0;
while (my $line = <INF>) {
	if (defined $SKIP_LINES and $lineNum++ < $SKIP_LINES) {
		#print $line;
		next;
	}
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	if (defined $val and $val ne '' and $val =~ /[-+]?[0-9]*\.?[0-9]+/) {
		print "$line\n" if (($val >= $top and $TOP_OR_BOTTOM eq 'top') or ($val <= $bottom and $TOP_OR_BOTTOM eq 'bottom'));
	}
}
close(INF);

exit;

