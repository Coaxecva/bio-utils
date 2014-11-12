#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Calculate the variance between two columns in two files.
# Author:	mdb
# Created:	2/22/12
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];	# input filename 1
my $INPUT_FILE2 = $ARGV[1];	# input filename 2
my $COL1 = $ARGV[2]; 		# column number in file 1, starting at 0
my $COL2 = $ARGV[3]; 		# column number in file 2, starting at 0
my $SKIP_LINES = $ARGV[4];	# optional number of header lines to skip
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_var.pl <file1> <file2> <column1> <column2> [skip_lines]\n" if (@ARGV < 4);

my (@vals1, @vals2);

open(INF, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while (defined $SKIP_LINES and $SKIP_LINES--) {
	<INF>;
}
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	my $val = $tok[$COL1];
	next if (not defined $val or $val eq '');
	push @vals1, $val;
}
close(INF);

open(INF, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while (defined $SKIP_LINES and $SKIP_LINES--) {
	<INF>;
}
while (<INF>) {
	chomp;
	my @tok = split /\t/;
	my $val = $tok[$COL2];
	next if (not defined $val or $val eq '');
	push @vals2, $val;
}
close(INF);

die "Files have different numbers of lines\n" if (@vals1 != @vals2);

my $count = 0;
my $totalDiff = 0;
for (my $i = 0;  $i < @vals1;  $i++) {
	my $v1 = $vals1[$i];
	my $v2 = $vals2[$i];
	my $avg = ($v1+$v2)/2;
	my $diff = abs($v1-$v2);
#	if ($avg > 0) {
#		my $rel = $diff/$avg;
#		die if ($rel >= 1/100);
#	}
	$totalDiff += $diff;
	$count++;	
}

print "Count: $count\n";
print "Mean difference:  " . ($totalDiff/$count) . "\n";

exit;

