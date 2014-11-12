#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Maps coverage regions (.coverage) to known gene annotation (.GFF)
#           and generates list of gene coverage regions (.genecoverage) and 
#           a report of hit genes (.genecoverage.txt).
# Author:	mdb
# Created:	9/9/10
#-------------------------------------------------------------------------------
# Parameters used to determine input/output filenames,
# e.g. "subset4a",200,6 for "subset4a_200bp_6x.coverage"
my $PREFIX         = $ARGV[0];
my $MIN_CONT_BASES = $ARGV[1];
my $MIN_CONT_COV   = $ARGV[2];
die "Usage: gene_coverage.pl <prefix> <min_len> <min_cov>\n" if ($#ARGV+1 < 3);

my $INPUT_GFF_FILE = "/scr1/mbomhoff/MGI_GTGUP.gff";

# Inputs for individual subset runs:
my $INPUT_COV_FILE = $PREFIX . "_" . $MIN_CONT_BASES . "bp_" . $MIN_CONT_COV . "x.coverage";
my $OUTPUT_GENECOV_FILE = $PREFIX . "_" . $MIN_CONT_BASES . "bp_" . $MIN_CONT_COV . "x.genecoverage";
my $OUTPUT_REPORT_FILE = $PREFIX . "_" . $MIN_CONT_BASES . "bp_" . $MIN_CONT_COV . "x.genecoverage.txt";
# Inputs for subset overlap regions:
#my $INPUT_COV_FILE = "subset4_overlap_" . $MIN_CONT_COV . "x.coverage";
#my $OUTPUT_GENECOV_FILE = "subset4_overlap_" . $MIN_CONT_COV . "x.genecoverage";
#my $OUTPUT_REPORT_FILE = "subset4_overlap_" . $MIN_CONT_COV . "x.genecoverage.txt";

my $MIN_OVERLAP = 200; # min overlap required between fragment and gene (in basepairs)
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/homeB/home4/u20/mbomhoff/scripts/";
use gff;

my $startTime = time;

my $pgenes = gff::LoadGFF($INPUT_GFF_FILE);
my $pcov = loadCoverage($INPUT_COV_FILE);

open(OUTF, ">", $OUTPUT_GENECOV_FILE) or 
		die("Error: cannot open file '$OUTPUT_GENECOV_FILE'\n");
		
open(OUTF2, ">", $OUTPUT_REPORT_FILE) or 
		die("Error: cannot open file '$OUTPUT_REPORT_FILE'\n");

my %geneHits;
my $hitCount = 0;
my $totalGenes = 0;
my ($minOverlap, $maxOverlap) = (9999999, 0);
my ($minHits, $maxHits) = (9999999, 0);
foreach my $ref (sort keys %$pgenes) {
	foreach my $gene (@{$pgenes->{$ref}}) {
		$totalGenes++;
		my $gname = $gene->{name};
		my $gs = $gene->{start};
		my $ge = $gene->{end};
		foreach my $c (@{$pcov->{$ref}}) {
			my $cs = $c->{start};
			my $ce = $c->{end};
			my $overlap = getOverlap($gs, $ge, $cs, $ce);
			if ($overlap >= $MIN_OVERLAP) {
				print OUTF "$overlap\t$ref\t$cs\t$ce\t$gname\t$gs\t$ge\n";
				$hitCount++;
				$geneHits{$gname}++;
				$c->{hits}++;
				$minHits = min($minHits, $geneHits{$gname});
				$maxHits = max($maxHits, $geneHits{$gname});
			}
			if ($overlap > 0 and ($cs < $gs or $ce > $ge)) {
				my $os = ($cs <= $gs ? $cs - $gs : "!");
				my $oe = ($ce >= $ge ? $ce - $ge : "!");
				$c->{overhang}++;
				$c->{hits}++;
				print "$overlap\t$os\t$oe\t$cs\t$ce\t$gs\t$ge\n";
				$minOverlap = min($minOverlap, $overlap);
				$maxOverlap = max($maxOverlap, $overlap);
			}
		}
	}
}
close(OUTF);

my $totalRegions = 0;
my $regionsHit = 0;
my $regionsWithOverhang = 0;
foreach my $ref (keys %$pcov) {
	$totalRegions += scalar @{$pcov->{$ref}};
	foreach my $c (@{$pcov->{$ref}}) {
		$regionsHit++ if (defined $c->{hits});
		$regionsWithOverhang++ if (defined $c->{overhang});
	}
}

my $numGenesHit = scalar keys %geneHits;
my $avgHitsPerGene = ($numGenesHit > 0 ? ($hitCount / $numGenesHit) : 0);
my $variance = variance($avgHitsPerGene, values %geneHits) if ($numGenesHit > 0);
print OUTF2 "Regions loaded:      $totalRegions\n";
print OUTF2 "Regions hit:         $regionsHit\n";
print OUTF2 "Regions overhanging: $regionsWithOverhang\n";
print OUTF2 "Genes loaded:        $totalGenes\n";
print OUTF2 "Genes hit:           $numGenesHit\n";
print OUTF2 "Avg per gene:        $avgHitsPerGene\n" if ($numGenesHit > 0);
print OUTF2 "Variance:            $variance\n" if ($numGenesHit > 0);
print OUTF2 "Hits Min/Max:        $minHits, $maxHits\n" if ($numGenesHit > 0);
print OUTF2 "Overlap Min/Max:     $minOverlap, $maxOverlap\n" if ($numGenesHit > 0);
foreach my $gname (sort keys %geneHits) {
	print OUTF2 "$gname\t$geneHits{$gname}\n";	
}

print "All done! (hits=$hitCount time=" . (time-$startTime) . "s)\n";
exit;

#-------------------------------------------------------------------------------
sub variance {
	my $avg = shift;
	my @array = shift;
	
	my $num = scalar @array;
	my $sum = 0;
	
	foreach my $x (@array) {
		my $v = $x - $avg;
		$sum += $v * $v / $num;
	}
	
	return $sum;
}
#-------------------------------------------------------------------------------
sub loadCoverage {
	my $filename = shift;
	my $pout;
	my $count = 0;

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
			
		my $name = gff::GetRefName($ref) or die "Error converting reference name!";
			
		push @{ $pout->{$name} }, { start => $start, end => $end };
		$count++;
	}
	
	close(INF);
	
	print "$count fragments loaded\n";

	return $pout;
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

