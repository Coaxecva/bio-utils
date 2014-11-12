#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Categorize gene locations as coding/exonic.
# Author:	mdb
# Created:	5/18/11
#------------------------------------------------------------------------------
my $GENE_NAME = $ARGV[0];
my $POSITION = $ARGV[1]; # 1's-based BP position in gene, or name of file with one position per line
my $GTF_FILE = '/data/genome/mus/combined.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_categorize.pl <gene_name>\n" if (@ARGV < 1);

my ($start, $end, $pExons, $pCDS) = loadGene($GTF_FILE, $GENE_NAME);
my $len = $end-$start+1;
die "Gene not found!\n" if (not defined $pExons);

my $transOfs = 0;
for (my $pos = $start;  $pos <= $end;  $pos++) {
	my $geneOfs = $pos - $start;
	my $revGeneOfs = $len - $geneOfs;
	
	foreach my $r (@$pCDS) {
		if ($pos >= $r->{start} and $pos <= $r->{end}) {
			print "$pos,$geneOfs,$revGeneOfs,$transOfs: CDS $r->{start}:$r->{end}\n";
			$transOfs++;
			goto NEXT;
		}
	}
	
#	foreach my $r (@$pExons) {
#		if ($abs >= $r->{start} and $abs <= $r->{end}) {
#			print "$pos,$rev,$abs: Exon $r->{start}:$r->{end}\n";
#			goto NEXT;
#		}
#	}
	
#	print "$pos,$rev,$abs:\n";
	
	NEXT:
}

exit;

#-------------------------------------------------------------------------------
sub loadGene {
	my $filename = shift;
	my $geneName = shift;
	my ($geneStart, $geneEnd);
	my @exons;
	my @cds;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		next if (not defined $name or $name ne $geneName);
		
		if ($type eq 'gene') {
			$geneStart = $start;
			$geneEnd = $end;
		}
		elsif ($type eq 'exon') {
			my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
			die if (not defined $transName);
			
			push @exons, { start => $start, end => $end };
		}
		elsif ($type eq 'cds') {
			my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
			die if (not defined $transName);
			
			push @cds, { start => $start, end => $end };
		}
	}
	close(INF);
	
	return ($geneStart, $geneEnd, \@exons, \@cds);
}
