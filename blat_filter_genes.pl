#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/16/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/workspace/Pilot";
use Pilot;

die "Usage:  blat_filter_genes.pl <filename>\n" if (@ARGV < 1);

#my $pGenes = loadGenes();
my $pExons = loadExons();

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

#my $pastHeader = 0;
#while (not $pastHeader) {
#	my $line = <INF>;
#	print $line;
#	$pastHeader = 1 if ($line =~ /^\-\-\-\-\-/);
#}
	
while (my $line = <INF>) {
	my ($matches) = $line =~ /^(\d+)/;
	next if ($matches < 100);
	
	chomp $line;
	my @tok = split(/\t/, $line);
	my $tName = $tok[13];
	if ($tName =~ /^chr(\S+)/) {
		$tName = $1;	
	}
#	my $tStart = $tok[15];
#	my $tEnd = $tok[16];
	
	my @blockSizes = split(',', $tok[18]);
	my @tStarts = split(',', $tok[20]);
	
#	foreach my $geneID (keys %{$pGenes->{$tName}}) {
#		my $pGene = $pGenes->{$tName}{$geneID}[0];
	foreach my $exonID (keys %{$pExons->{$tName}}) {
		foreach my $exon (@{$pExons->{$tName}{$exonID}}) {
			for (my $i = 0;  $i < @tStarts;  $i++) {
				my $ts = $tStarts[$i];
				my $te = $ts + $blockSizes[$i] - 1;
				if (isOverlapping($ts, $te, $exon->{start}, $exon->{end})) {
					print "$line\n";
					goto NEXT_LINE;
				}
			}
		}
	}
	NEXT_LINE:
}
close(INF);

exit;

