#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Perform binomial test on specified table columns
# Author:	mdb
# Created:	2/9/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input SNP_*.pileup.summary.table filename
my $COL1 = 5;	# 0-based column number for first count
my $COL2 = 8;	# 0-based column number for second count
my $P_VALUE_CUTOFF = 0.05;
my $MIN_EFFECT_SIZE = 0.1;
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Math::CDF qw{pbinom};

die "Usage:  bintest_table.pl <filename>n" if (@ARGV < 1);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

while (my $line = <$inf>) {
	if ($line =~ /^#/) {
		print $line;
		next;	
	}
	chomp $line;
	my @tok = split(/\t/, $line);
	my ($count1, $count2) = ($tok[$COL1], $tok[$COL2]);

	my $left  = 0.5 - $MIN_EFFECT_SIZE;
	my $right = 0.5 + $MIN_EFFECT_SIZE;	
	my $total = $count1 + $count2;
	my $freq1 = $count1 / $total;
	my $freq2 = $count2 / $total;
	
	next if	($freq1 >= $left and $freq1 <= $right) or
			($freq2 >= $left and $freq2 <= $right);
	
	my $minor = ($count1 < $count2 ? $count1 : $count2);
	my $p = pbinom($minor, $total, 0.5);
	#next if ($p > $P_VALUE_CUTOFF);
	
	print "$line\t$p\n";
}
close ($inf);

exit;

#-------------------------------------------------------------------------------
