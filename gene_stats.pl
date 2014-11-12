#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Info on specified gene in GTF/GFF file.
# Author:	mdb
# Created:	4/21/11
#------------------------------------------------------------------------------
my $GENE_NAME = $ARGV[0];
#my $GTF_FILE = '/data/genome/mus/ensembl63/combined.gtf';
my $GTF_FILE = '/data/genome/mus/ensembl63/filtered.Mus_musculus.NCBIM37.63.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gene_stats.pl <gene_name>\n" if ($#ARGV+1 < 1);

my $pGene = loadGene($GTF_FILE, $GENE_NAME);

if (not defined $pGene) {
	die "Gene not found!\n";
}

print "Gene '$GENE_NAME':\n";
foreach my $transName (sort keys %$pGene) {
	print "   $transName:\n";
	foreach my $type (sort keys %{$pGene->{$transName}}) {
		next if (not defined $pGene->{$transName}{$type});
		foreach my $r (sort {$a->{start} <=> $b->{start}} @{$pGene->{$transName}{$type}}) {
			my $len = $r->{end} - $r->{start} + 1;
			print "      $type ($r->{id}): $r->{start}-$r->{end} ($len), strand=$r->{strand}, frame=$r->{frame}\n";
		}
	}
}

exit;

#-------------------------------------------------------------------------------
sub loadGene {
	my $filename = shift;
	my $geneName = shift;
	my %gene;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $chr    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $frame  = $tok[7];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		my ($id) = ($attr =~ /gene_id \"(\S+)\"/);
#		if ($end < $start) {
#			print "Warning: $type '$name' has invalid coordinates: $start $end\n";
#		}
		next if (not defined $name or $name ne $geneName);

		# Extract chromosome number
		if ($chr =~ /chr(\w+)/) {
			$chr = $1;
		}
		
		# Parse transcript name
		my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
		$transName = $type if (not defined $transName);

		push @{$gene{$transName}{$type}}, { id => $id, start => $start, end => $end, strand => $strand, frame => $frame };
	}
	close(INF);
	
	return \%gene;
}

