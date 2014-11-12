#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Maps coverage regions (.coverage) to known gene annotation (.GFF)
#           and generates list of gene coverage regions (.genecoverage) with
#           sequence.
# Author:	mdb
# Created:	10/14/10
#-------------------------------------------------------------------------------
# Parameters used to determine input/output filenames,
# e.g. "subset4a",200,6 for "subset4a_200bp_6x.coverage"
my $PREFIX         = $ARGV[0];
my $MIN_CONT_BASES = $ARGV[1];
my $MIN_CONT_COV   = $ARGV[2];
die "Usage: gene_coverage2.pl <prefix> <min_len> <min_cov>\n" if ($#ARGV+1 < 3);

my $INPUT_GFF_FILE = "/scr1/mbomhoff/MGI_GTGUP.gff";
my $INPUT_COV_FILE = $PREFIX . "_" . $MIN_CONT_BASES . "bp_" . $MIN_CONT_COV . "x.coverage";
my $OUTPUT_GENECOV_FILE = $PREFIX . "_" . $MIN_CONT_BASES . "bp_" . $MIN_CONT_COV . "x.genecoverage";

my $MIN_OVERLAP = 50; # min overlap required between fragment and gene (in basepairs)
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
		
foreach my $ref (sort keys %$pgenes) {
	foreach my $gene (@{$pgenes->{$ref}}) {
		my $gname = $gene->{name};
		my $gs = $gene->{start};
		my $ge = $gene->{end};
		foreach my $c (@{$pcov->{$ref}}) {
			my $cs = $c->{start};
			my $ce = $c->{end};
			my $overlap = getOverlap($gs, $ge, $cs, $ce);
			if ($overlap >= $MIN_OVERLAP) {
				my $seq = getOverlapSeq($gs, $ge, $cs, $ce, $c->{seq});
				print OUTF "$gname\t$overlap\t$cs\t$ce\t$seq\n";
			}
		}
	}
}
close(OUTF);

print "All done! (time=" . (time-$startTime) . "s)\n";
exit;

#-------------------------------------------------------------------------------
sub loadCoverage {
	my $filename = shift;
	my $pout;
	my $count = 0;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $line;
	my $lineNum = 0;
	my @tok;
	while( $line = <INF> ) {
		$lineNum++;
		chomp $line;
		@tok = split /\t/,$line;
		my $ref   = $tok[0];
		my $start = $tok[1];
		my $end   = $tok[2];
		my $seq   = $tok[4];
		
		die "Error: columns missing in coverage file\n" if (scalar @tok < 5);
		die "Error: invalid sequence length, line $lineNum\n" if (length $seq == 0 or length $seq != ($end-$start+1));
			
		my $name = gff::GetRefName($ref) or die "Error converting reference name!";
			
		push @{ $pout->{$name} }, { start => $start, end => $end, seq => $seq };
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
sub getOverlapSeq{
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	my $seq = shift;
	
	my $s = max($s1, $s2);
	my $e = min($e1, $e2);
	
	my $start_ofs = $s - $s2;
	return substr($seq, $start_ofs, $e - $s + 1);
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

