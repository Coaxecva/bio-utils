#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/28/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL1 = $ARGV[1]; 		# column number, starting at 0
my $COL2 = $ARGV[2]; 		# column number, starting at 0
my $SKIP_LINES = 0;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_match.pl <input_filename> <col1> <col2>\n" if ($#ARGV+1 < 3);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

# Skip header
while ($SKIP_LINES--) {
	<INF>;
}

my $lineNum = 0;
my %col1;
my %col2;
while (<INF>) {
	$lineNum++;
	chomp;
	my @tok = split(/\s+/);
	die "Error: column $COL1 doesn't exist in file on line $lineNum\n" if (not defined $tok[$COL1]);
	die "Error: column $COL2 doesn't exist in file on line $lineNum\n" if (not defined $tok[$COL2]);
	$col1{$tok[$COL1]}++;
	$col2{$tok[$COL2]}++;
}
close(INF);

my %common;
foreach my $x (keys %col1) {
	$common{$x}++ if (defined $col2{$x});
}
foreach my $x (keys %col2) {
	$common{$x}++ if (defined $col1{$x});
}

print "Common:\n";
foreach (sort keys %common) {
	print "$_\n";	
}

print "Unique to column 1:\n";
foreach (sort keys %col1) {
	print "$_\n" if (not defined $common{$_});
}

print "Unique to column 2:\n";
foreach (sort keys %col2) {
	print "$_\n" if (not defined $common{$_});
}

exit;

