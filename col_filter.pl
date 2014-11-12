#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print lines with specified column that passes the given filter.
#           Example:  col_filter.pl test.csv 0 >=0.3
# Author:	mdb
# Created:	5/4/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
my $EXPR = $ARGV[2];		# filter expression
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_filter.pl <filename> <column_num> <expr>\n" if ($#ARGV+1 < 3);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	next if (not defined $tok[$COL]);
	print "$_\n" if (eval("$tok[$COL] $EXPR"));
}
close(INF);

exit;

