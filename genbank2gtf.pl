#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extracts genes from genbank files in GTF format.
# Author:	mdb
# Created:	8/15/11
#-------------------------------------------------------------------------------
my @GENBANK_INPUT_FILES = <Mus_musculus*.dat>;
# The GenBank .dat files come from the Ensembl FTP site.  To download them use:
#    wget -q ftp://ftp.ensembl.org/pub/current/genbank/mus_musculus/
#    gunzip *.dat.gz
#my %CHROMOSOMES = map {$_=>1} (1..19, 'X', 'Y', 'MT');
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Bio::SeqIO;

foreach my $file (@GENBANK_INPUT_FILES) {
	my $seqio = Bio::SeqIO->new(-file => $file, -format => 'genbank');
	while (my $seq = $seqio->next_seq) {
		my (undef, undef, $seqChr, $seqStart, $seqEnd) = split(':', $seq->accession_number);
		#next if (not defined $CHROMOSOMES{$seqChr});
		
		# Extract gene features
		my @features = grep { $_->primary_tag eq 'gene' } $seq->get_SeqFeatures;
		foreach my $f (@features) {
			my ($mgiName, $ensemblID, $note) = ('', '', '');
			if ($f->has_tag('locus_tag')) {
				($mgiName) = $f->get_tag_values('locus_tag');
			}
			else { die };
			
			if ($f->has_tag('gene')) {
				($ensemblID) = $f->get_tag_values('gene');
			}
			else { die };
			
			if ($f->has_tag('note')) {
				($note) = $f->get_tag_values('note');
				next if ($note =~ /pseudogene/);
			}
			
			my $start = $f->location->start + $seqStart - 1;
			my $end = $f->location->end + $seqStart - 1;
			
			next if (not defined $f->strand);
			my $strand = ($f->strand == 1 ? '+' : '-');
			print "$seqChr\tEnsembl\tGene\t$start\t$end\t.\t$strand\t.\tgene_name \"$mgiName\"; gene_id \"$ensemblID\";" . ($note ? " note \"$note\";" : '') . "\n";
		}
	}
}

exit;
#-------------------------------------------------------------------------------

