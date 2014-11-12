#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Split a pileup file into sections by gene, filter out non-genic.
# Author:	mdb
# Created:	9/14/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input pileup/VCF filename
my $OUTPUT_FILE = "$INPUT_FILE.bygene";

my %CHROMOSOMES = map {$_ => 1} (1..19, 'X', 'Y', 'MT');
my $MIN_DEPTH = 10;

my $ANNOT_FILE = '/data/genome/mus/ensembl63/combined.gtf';
my $ANNOT_BIN_SZ = 1000000;
# Note on binning:  bin should be at least 1/3 size of largest annotation.
#-------------------------------------------------------------------------------

use warnings;
use strict;
#use diagnostics;

die "Usage:  pileup_split_by_gene <pileup>\n" if ($#ARGV+1 < 1);

my $pAnnot = loadGFF($ANNOT_FILE);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my %genes;
my $count = 0;
$| = 1;

while (my $line = <$inf>) {
	my @tok = split(/\t/, $line);
	my $ref  = $tok[0];
	my $pos  = $tok[1];
	
	next if (not defined $CHROMOSOMES{$ref});

#	my ($ref, $pos, $refbase, $base) = $line =~ /^(\w+)\t(\d+)\t(\w)\t(\w)/;
	
	print "\r$ref " . commify($pos) . "          \r" if ((++$count % 100000) == 0);
	
	# Search all annotations
	my %found;
	foreach my $i (0, -1, 1) {
		my $bin = int($pos/$ANNOT_BIN_SZ) + $i;
		foreach my $name (keys %{$pAnnot->{$ref}{$bin}}) {
			next if (defined $found{$name});

			my $a = $pAnnot->{$ref}{$bin}{$name};
			if ($pos >= $a->{start} and $pos <= $a->{end}) { # overlapping
				$found{$name}++;
				
				my $refbase = $tok[2];
				my $base = $tok[3];
				my $depth = $tok[7];
				next if ($depth < $MIN_DEPTH or $base eq 'N' or $refbase eq '*' or length $base > 1);
				
				push @{$genes{$name}}, $line;
				# can't break here b/c of potential overlapping annotations
			}
		}
	}
}
close($inf);

$| = 0;
open(my $outf, '>', $OUTPUT_FILE) or 
	die("Error: cannot open file '$OUTPUT_FILE'\n");
foreach my $name (sort keys %genes) {
	print {$outf} ">$name\n";
	foreach (@{$genes{$name}}) {
		print {$outf} "$_";	
	}
}
close($outf);

exit;

#-------------------------------------------------------------------------------
sub commify {
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

sub loadGFF {
	my $filename = shift;
	my $pout;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while (<INF>) {
		chomp;
		my @tok = split(/\t/);
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'gene' and $type ne 'cds');
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding entry due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		# Parse name from attributes field
		my $geneName;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$geneName = $1;
		}
		#my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
		
		# Bin into hash
		if ($type eq 'gene') {
			my $bin = int($start/$ANNOT_BIN_SZ);
			$pout->{$ref}{$bin}{$geneName}{start} = $start;
			$pout->{$ref}{$bin}{$geneName}{end} = $end;
			
			my $len = $end-$start+1;
			print "Warning: size greater than expected: $len\n" if ($len > $ANNOT_BIN_SZ*3);
		}
		elsif ($type eq 'cds') {
			my $bin = int($start/$ANNOT_BIN_SZ);
			$pout->{$ref}{$bin}{$geneName}{cds}++;
		}
	}
	close(INF);
	
	# Remove non-coding genes and CDS w/o corresponding gene
	my $count = 0;
	foreach my $ref (keys %$pout) {
		foreach my $bin (keys %{$pout->{$ref}}) {
			foreach my $geneName (keys %{$pout->{$ref}{$bin}}) {
				if ($pout->{$ref}{$bin}{$geneName} == 0
					or not defined $pout->{$ref}{$bin}{$geneName}{start}) 
				{
					delete $pout->{$ref}{$bin}{$geneName};	
				}
				else {
					$count++;
				}
			}	
		}
	}
	print "Genes loaded: $count\n";

	return $pout;
}
