#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/4/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_unique.pl <filename> <column>\n" if (@ARGV < 2);

my %unique;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	my $val = $tok[$COL];
	next if (not defined $val);
	$unique{$val}++;
}
close(INF);

foreach (sort keys %unique) {
	print "$_\n";	
}

exit;

