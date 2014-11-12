#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/19/11
#------------------------------------------------------------------------------
my $GENE_NAME = $ARGV[0];
my $GTF_FILE = '/data/genome/mus/combined.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_parse_gene.pl <gene_name>\n" if (@ARGV < 1);

my $pGene = loadGene($GTF_FILE, $GENE_NAME);

print "Name:   $GENE_NAME\n";
print "Start:  $pGene->{start}\n";
print "End:    $pGene->{end}\n";
print "Strand: $pGene->{strand}\n";
print "Transcripts:\n";
foreach my $transName (sort keys %{$pGene->{exons}}) {
	print "   $transName:\n";
	foreach my $r (sort {$pGene->{strand} eq '+' ? $a->{start} <=> $b->{start} : $b->{start} <=> $a->{start}} @{$pGene->{exons}{$transName}}) {
		print "      $r->{start}:$r->{end}\n";
	}
}

exit;

#-------------------------------------------------------------------------------
sub loadGene {
	my $filename = shift;
	my $geneName = shift;
	my %out;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
	    my $strand = $tok[6];
		my $frame  = $tok[7];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		# Parse gene name and transcript name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		next if (not defined $name or $name ne $geneName);
		
		if ($type eq 'gene') {
			$out{strand} = $strand;
			$out{start} = $start;
			$out{end} = $end;
		}
		elsif ($type eq 'exon') {
			my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
			die if (not defined $transName);
		
			push @{$out{exons}{$transName}}, { start => $start, end => $end };
		}
	}
	close(INF);
	
	return \%out;
}
