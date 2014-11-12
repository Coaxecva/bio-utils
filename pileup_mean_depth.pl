#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Calculate the mean read depth for all positions in the given
#           pileup file, include all bases regardless of quality.
# Author:	mdb
# Created:	9/14/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input pileup/VCF filename
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_mean_depth.pl <pileup>\n" if ($#ARGV+1 < 1);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $parsex = qr/^(\S+)\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t(\S+)/;
my %total;
my %count;

while (my $line = <$inf>) {
	my ($ref, $depth) = $line =~ $parsex;
	
	my $type;
	if ($ref =~ /\d+/ and $ref >= 1 and $ref <= 19) {
		$type = 'Autosomes';
	}
	elsif ($ref eq 'X') {
		$type = 'X';
	}
	else {
		next;
	}
	
	$total{$type} += $depth;
	$count{$type}++;
}
close($inf);

foreach my $type (sort keys %total) {
	print "$type: $total{$type}/$count{$type} " . ($total{$type}/$count{$type}) . "\n";	
}

exit;

#-------------------------------------------------------------------------------
