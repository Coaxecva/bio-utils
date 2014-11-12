#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Replace specified column with given value.
# Author:	mdb
# Created:	2/1/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
my $VAL = $ARGV[2];			# replacement value
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_replace.pl <filename> <column_num> <val>\n" if ($#ARGV+1 < 3);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	next if (not defined $tok[$COL]);
	for (my $i = 0;  $i < @tok;  $i++) {
		if ($i == $COL) {
			print $VAL;
		}
		else {
			print $tok[$i];	
		}
		print "\t" if ($i != $#tok);
	}
	print "\n";
}
close(INF);

exit;

