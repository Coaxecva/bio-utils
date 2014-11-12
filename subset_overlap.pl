#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Analyzes several sets of coverage regions for overlap of a specified
#           amount and generates a list of overlapping coverage regions common
#           to all sets.
# Author:	mdb
# Created:	9/10/10
#-------------------------------------------------------------------------------

my $MIN_COVERAGE = $ARGV[0]; # min coverage depth (only used to set input filenames)
die "Usage: subset_overlap.pl <min_cov>\n" if ($#ARGV+1 < 1);

my $MIN_OVERLAP = 200;  # min overlap between coverage regions (in basepairs)

# List of inputs for Bowtie runs:
#my @INPUT_COV_FILES = ( 
#	"/scr1/mbomhoff/subset4a_200bp_" . $MIN_COVERAGE . "x.coverage",
#	"/scr1/mbomhoff/subset4b_200bp_" . $MIN_COVERAGE . "x.coverage",
#	"/scr1/mbomhoff/subset4c_200bp_" . $MIN_COVERAGE . "x.coverage",
#	"/scr1/mbomhoff/subset4d_200bp_" . $MIN_COVERAGE . "x.coverage",
#	"/scr1/mbomhoff/subset4e_200bp_" . $MIN_COVERAGE . "x.coverage"
#);

# List of inputs for TopHat runs:
my @INPUT_COV_FILES = ( 
	"/bio5/mbomhoff/tophat4a_u/accepted_hits_200bp_" . $MIN_COVERAGE . "x.coverage",
	"/bio5/mbomhoff/tophat4b_u/accepted_hits_200bp_" . $MIN_COVERAGE . "x.coverage",
	"/bio5/mbomhoff/tophat4c_u/accepted_hits_200bp_" . $MIN_COVERAGE . "x.coverage",
	"/bio5/mbomhoff/tophat4d_u/accepted_hits_200bp_" . $MIN_COVERAGE . "x.coverage",
	"/bio5/mbomhoff/tophat4e_u/accepted_hits_200bp_" . $MIN_COVERAGE . "x.coverage"
);

my $OUTPUT_COV_FILE = "subset4_overlap_" . $MIN_COVERAGE . "x.coverage";

#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/homeB/home4/u20/mbomhoff/scripts/";
use gff;

my $startTime = time;

open(OUTF, ">", $OUTPUT_COV_FILE) or 
	die("Error: cannot open file '$OUTPUT_COV_FILE'\n");

my %bins;
for (my $i = 0;  $i < scalar @INPUT_COV_FILES;  $i++) {
	loadCoverage($INPUT_COV_FILES[$i], $i, \%bins);
}

print "Searching bins:\n";
foreach my $ref (sort keys %bins) {
	my $name = gff::GetRefName($ref);
	print "   $name\n";
	foreach my $c0 (sort {$a->{start} <=> $b->{start}} @{$bins{$ref}{0}}) {
		my $s = $c0->{start};
		my $e = $c0->{end};
		my $count = 1;
		for (my $i = 1;  $i < scalar @INPUT_COV_FILES;  $i++) {
			foreach my $c (@{$bins{$ref}{$i}}) {
				if (getOverlap($c0->{start}, $c0->{end}, $c->{start}, $c->{end}) >= $MIN_OVERLAP) {
					$count++;
					my ($x, $y) = getOverlapCoord($c0->{start}, $c0->{end}, $c->{start}, $c->{end});
					$s = max($s, $x);
					$e = min($e, $y);
					last;
				}
			}
		}
		my $len = $e - $s + 1;
		if ($count == scalar @INPUT_COV_FILES and $len >= $MIN_OVERLAP) {
			print OUTF "$name\t$s\t$e\t$len\n";
		}
	}
}

close(OUTF);
print "All done! (time=" . (time-$startTime) . "s)\n";
exit;

#-------------------------------------------------------------------------------
sub loadCoverage {
	my $filename = shift;
	my $index = shift;
	my $pout = shift;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $line;
	my @tok;
	while( $line = <INF> ) {
		@tok = split /\t/,$line;
		my $ref   = $tok[0];
		my $start = $tok[1];
		my $end   = $tok[2];
		
		die "Error: invalid line in file\n" if (not defined $end);
			
		my %coord = ( start => $start, end => $end );
		push @{ $pout->{$ref}{$index} }, \%coord;
	}
	
	close(INF);
}
#-------------------------------------------------------------------------------
sub isOverlapping {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return (($s1 >= $s2 && $s1 <= $e2) ||
			($e1 >= $s2 && $e1 <= $e2) ||
			($s2 >= $s1 && $s2 <= $e1) ||
			($e2 >= $s1 && $e2 <= $e1));
}
#-------------------------------------------------------------------------------
sub getOverlap {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return 0 if (not isOverlapping($s1, $e1, $s2, $e2));
	
	my $s = max($s1, $s2);
	my $e = min($e1, $e2);
	
	return ($e - $s + 1);
}
#-------------------------------------------------------------------------------
sub getOverlapCoord {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	my $s = max($s1, $s2);
	my $e = min($e1, $e2);
	
	return ($s, $e);
}
#-------------------------------------------------------------------------------
sub min {
	my $x = shift;
	my $y = shift;
	return $x if ($x <= $y);
	return $y;	
}
sub max {
	my $x = shift;
	my $y = shift;
	return $x if ($x >= $y);
	return $y;
}
#-------------------------------------------------------------------------------
