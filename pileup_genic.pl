#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print lines from given mpileup file that fall within annotated genes.
# Author:	mdb
# Created:	9/14/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input mpileup/VCF filename
my $MIN_ALLELE_FREQ = 0.1;	# min allele frequency
my $MIN_ALLELE_COUNT = 4;	# min HQ depth of allele
my $MIN_DEPTH = 10;
my %CHROMOSOMES = map {$_ => 1} (1..19, 'X', 'Y', 'MT');
my $GENE_FILE = '/data/genome/mus/ensembl63/filtered.combined.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_genic.pl <mpileup>\n" if ($#ARGV+1 < 1);

my $pAnnot = loadAnnot($GENE_FILE, 'gene');
my ($pBins, $binSz) = makeBins($pAnnot);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $parsex = qr/^(\S+)\t(\S+)\t\S+\t(\S+)\t\S+\t\S+/;

while (my $line = <$inf>) {
	chomp $line;
	my ($ref, $pos, $depth) = $line =~ $parsex;
	next if (not defined $CHROMOSOMES{$ref});
	next if ($depth < $MIN_DEPTH);

	# Search all annotations
	foreach my $i (0, -1, 1) {
		my $bin = int($pos/$binSz) + $i;
		foreach my $name (keys %{$pAnnot->{$ref}{$bin}}) {
			my $a = $pAnnot->{$ref}{$bin}{$name};
			if ($pos >= $a->{start} and $pos <= $a->{end}) { # overlapping
				print $line . "\n";
				goto NEXT_LINE;
			}
		}
	}
	NEXT_LINE:
}
close($inf);

#print STDERR "Total genes: " . (keys %genes) . "\n";

exit;

#-------------------------------------------------------------------------------
sub loadAnnot {
	my $filename = shift;
	my $userType = shift;
	my $pout;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while (<INF>) {
		chomp;
		my @tok = split(/\t/);
		my $ref    = $tok[0];
		my $source = lc($tok[1]);
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne $userType);
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding entry due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		# Parse gene name and id from attributes field
		my ($geneID) = ($attr =~ /gene_id \"(\S+)\"/);
		die if (not defined $geneID);
		my ($geneName) = $attr =~ /gene_name \"(\S+)\"/;
		die if (not defined $geneName);
			
		if ($type eq 'gene') {
			push @{$pout->{$ref}{$geneID}}, { name => $geneName, start => $start, end => $end, strand => $strand };
		}
		else {
			push @{$pout->{$ref}{$geneID}}, { name => $geneName, start => $start, end => $end };
		}
	}
	close(INF);

	return $pout;
}

sub makeBins {
	my $pin = shift;
	my $pout;
	
	# First determine size of largest region
	my $maxSz;
	foreach my $ref (keys %$pin) {
		foreach my $id (keys %{$pin->{$ref}}) {
			foreach my $r (@{$pin->{$ref}{$id}}) {
				my $len = $r->{end} - $r->{start} + 1;
				$maxSz = $len if (not defined $maxSz or $len > $maxSz);
			}
		}
	}
	die if (not defined $maxSz);
	my $binSz = int($maxSz / 3) + 1; # bin size should be at least 1/3 of largest region
	#print "bin size = $binSz\n";
	
	# Bin regions by start position
	foreach my $ref (keys %$pin) {
		foreach my $id (keys %{$pin->{$ref}}) {
			foreach my $r (@{$pin->{$ref}{$id}}) {
				my $bin = int($r->{start}/$binSz);
				push @{$pout->{$ref}{$bin}{$id}}, $r;
			}
		}
	}
	
	return ($pout, $binSz);
}