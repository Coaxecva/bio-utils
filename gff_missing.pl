#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	8/15/11
#------------------------------------------------------------------------------
my $ANNOT_FILE = '/data/genome/mus/ensembl61/combined.gtf';
my $XREF_FILE = '/home/mbomhoff/Desktop/xref.txt';
#-------------------------------------------------------------------------------

use warnings;
use strict;

my @files = </data/query/17n/*.phylip>;
my ($pGenes, $pPseudo, $pCDS) = loadGenesByFileList(\@files);
#my $xref = loadXRef();

#my $mismatch = 0;
#foreach my $name (keys %$pGenes) {
#	die "$name not in xref\n" if (not defined $xref->{$name});
#	if ($pGenes->{$name}{start} != $xref->{$name}{start} or $pGenes->{$name}{end} != $xref->{$name}{end}) {
#		my $hasCDS = defined $pCDS->{$name};
#		print "mismatch $name mgi:$pGenes->{$name}{start}:$pGenes->{$name}{end} xref:$xref->{$name}{start}:$xref->{$name}{end} hasCDS=$hasCDS\n";	
#		$mismatch++;
#	}
#}
#print "Mismatches: $mismatch\n";

my $count = 0;
my $pseudos = 0;
foreach my $name (keys %$pCDS) {
	if (not defined $pGenes->{$name}) {
		my $ensemblID = $pCDS->{$name};
		#print "$name\n";
#		die "$name not found\n" if (not defined $xref->{$ensemblID});
		$count++;
		
		if (defined $pPseudo->{$name}) {
			$pseudos++;
		}
	}
}
print "Total: $count\n";
print "Pseudos: $pseudos\n";

#-------------------------------------------------------------------------------

sub loadXRef {
	my %out;
	
	open(INF, $XREF_FILE) or 
		die("Error: cannot open file '$XREF_FILE'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		$out{$tok[1]} = $out{$tok[0]} = { ensemblID => $tok[0], mgiID => $tok[1], chr => $tok[2], start => $tok[3], end => $tok[4] };
	}
	close(INF);
	
	return \%out;
}

sub loadGenesByFileList {
	my $pFileList = shift;
	
	my %names;
	foreach my $file (@$pFileList) {
		my ($geneName) = $file =~ /\S+\/(\S+)\.\w+/;
		$names{$geneName}++;
	}
	
	return loadGFF(\%names);
}

sub loadGFF {
	my $pList = shift; # optional hash ref of gene names to load
	my %genes;
	my %pseudogenes;
	my %cds;

	open(INF, $ANNOT_FILE) or 
		die("Error: cannot open file '$ANNOT_FILE'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $source = $tok[1];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);*/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		next if (not defined $name or not defined $pList->{$name});
		
		if ($type eq 'gene') {
			$genes{$name} = { start => $start, end => $end };
		}
		elsif ($type eq 'cds' and $source eq 'protein_coding') {
			my ($ensemblGeneID) = $attr =~ /gene_id \"(\S+)\"/;
			$cds{$name} = $ensemblGeneID;
		}
		
		if ($source eq 'pseudogene') {
			$pseudogenes{$name}++;
		}
	}
	close(INF);
	
	return (\%genes, \%pseudogenes, \%cds);
}
