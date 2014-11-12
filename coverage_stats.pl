#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	12/9/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  coverage_stats.pl <input_filename>\n" if ($#ARGV+1 < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $totalLen = 0;
my $minSize;
my $maxSize;
my $count = 0;

my $lineNum = 0;
my $line;
my @tok;
while ($line = <INF>) {
	$lineNum++;
	chomp $line;
	@tok = split /\t/, $line;
	#my $ref   = $tok[0];
	my $start = $tok[1];
	my $end   = $tok[2];
	#my $depth = $tok[3];
	
	die "Invalid format at line $lineNum\n" if (@tok != 4);
	die "Invalid coords at line $lineNum\n" if ($end < $start);
	
	my $len = $end-$start+1;
	$totalLen += $len;
	$maxSize = max($maxSize, $len);
	$minSize = min($minSize, $len); 	
	$count++;
}
close(INF);

print "Total length: $totalLen\n";
print "Num regions: $count\n";
print "Min region length: $minSize\n";
print "Max region length: $maxSize\n";

exit;

#-------------------------------------------------------------------------------
sub min {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x <= $y);
	return $y;
}

sub max {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x >= $y);
	return $y;
}
