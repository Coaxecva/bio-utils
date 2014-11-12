#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count number of duplicates in specified column in file.
# Author:	mdb
# Created:	6/22/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COLUMN_NUM = $ARGV[1];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_dups.pl <input_filename> <column_num>\n" if (@ARGV < 2);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my %seen;
while (<INF>) {
	chomp;
	my @tok = split /$DELIMITER/;
	my $val = $tok[$COLUMN_NUM];
	$seen{$val}++;
}
close(INF);

foreach my $val (keys %seen) {
	if ($seen{$val} > 1) {
		print "$val $seen{$val}\n";
	}
}

exit;

