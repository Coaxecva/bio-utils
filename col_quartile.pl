#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print values in specified column in top quartile.
# Author:	mdb
# Created:	5/4/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_quartile.pl <filename> <column_num>\n" if ($#ARGV+1 < 2);

my @lines;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	next if (not defined $tok[$COL]);
	push @lines, \@tok;
}
close(INF);

my $count = int(@lines * .25);
@lines = sort { $b->[$COL] <=> $a->[$COL] } @lines;
@lines = splice @lines, 0, $count;

foreach (sort @lines) {
	foreach (@$_) {
		print "$_\t";	
	}
	print "\n";
}

exit;

