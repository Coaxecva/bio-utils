#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/15/12
#------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

use warnings;
use strict;

# Skip header;
<>;
<>;
<>;
<>;
<>;

my %hits;
while (<>) {
	chomp;
	my @tok = split(/\t/);
	my $match 		= $tok[0];
	my $mismatch 	= $tok[1];
	my $query 		= $tok[9];
	my $qsize 		= $tok[10];
	my $target 		= $tok[13];
	my $tsize 		= $tok[14];
	my $blockSizes	= $tok[18];
	my $qStarts 	= $tok[19];
	my $tStarts 	= $tok[20];
	
	my @bSizes = split(',', $blockSizes);
	my @qS = split(',', $qStarts);
	my @tS = split(',', $tStarts);
	
	push @{$hits{$target}}, { match => $match, mismatch => $mismatch, query => $query,
								qsize => $qsize, tsize => $tsize,
								blockSizes => \@bSizes, qStarts => \@qS, tStarts => \@tS }
}

foreach my $target (keys %hits) {
	print "$target\n";
	my @sorted = sort {$b->{match} <=> $a->{match}} @{$hits{$target}};
	for (my $i = 0;  $i < 5;  $i++) {
		print "$sorted[$i]->{match} $sorted[$i]->{query} $sorted[$i]->{qsize}\n";	
	}
}

exit;

#-------------------------------------------------------------------------------
