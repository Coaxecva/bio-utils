#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Group lines by specified column above/below mean value.
# Author:	mdb
# Created:	5/5/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_group_by_mean.pl <filename> <column>\n" if (@ARGV < 2);

my @lines;
my $total = 0;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	next if (not defined $tok[$COL]);
	$total += $tok[$COL];
	push @lines, \@tok;
}
close(INF);

my $mean = $total / @lines;

print "mean = $mean\n";
print ">= mean\n";
foreach (@lines) {
	if ($_->[$COL] >= $mean) {
		foreach (@$_) { print "$_\t"; }
		print "\n";
	}
}

print "< mean\n";
foreach (@lines) {
	if ($_->[$COL] < $mean) {
		foreach (@$_) { print "$_\t"; }
		print "\n";
	}
}

exit;

