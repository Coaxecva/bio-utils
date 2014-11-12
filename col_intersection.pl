#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Left-join two tables in separate files on specified column.
# Author:	mdb
# Created:	5/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
my $COL = $ARGV[2];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_intersection.pl <file1> <file2> <col>\n" if (@ARGV < 3);

my %common;
open(my $f1, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while (<$f1>) {
	chomp;
	my @tok = split(/$DELIMITER/);
	my $val = $tok[$COL];
	$val =~ s/\"//g; # remove quotes
	$common{$val}++;
}
close($f1);

open(my $f2, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while (<$f2>) {
	chomp;
	my @tok = split(/$DELIMITER/);
	my $val = $tok[$COL];
	$val =~ s/\"//g; # remove quotes
	$common{$val}++;
}
close($f2);

foreach my $val (sort keys %common) {
	print "$val\n" if ($common{$val} == 2);	
}

exit;

