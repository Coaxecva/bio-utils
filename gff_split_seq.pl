#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Split input FASTA sequence into exons/introns according to GTF
#			annotation and output as FASTA file to stdout.
# Author:	mdb
# Created:	4/21/11
#------------------------------------------------------------------------------
my $INPUT_FASTA = $ARGV[0];
my $GENE_NAME = $ARGV[1];
my $SEC_NAME = $ARGV[2];
my $REV_COMP = 1; # has sequence in FASTA been reverse complemented?
my $GTF_FILE = '/data/genome/mus/combined.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_split_seq.pl <input_fasta_file> <gene_name> [sec_name]\n" if (@ARGV < 2);

my $seq = loadFASTA($INPUT_FASTA, $SEC_NAME);
$seq = reverse $seq if ($REV_COMP);

my ($start, $end, $strand, $pExons) = loadGene($GTF_FILE, $GENE_NAME);
die "Gene not found!\n" if (not defined $pExons);

foreach my $transName (sort keys %$pExons) {
	for (my $i = 0;  $i < @{$pExons->{$transName}};  $i++) {
		my $e1 = $pExons->{$transName}->[$i];
		my $e2 = $pExons->{$transName}->[$i+1];
		
		my $offset = $e1->{start} - $start;
		my $len = $e1->{end} - $e1->{start} + 1;
		die if ($len <= 0);
		
		my $subseq = substr($seq, $offset, $len);
		$subseq = reverse $subseq if ($REV_COMP);
		print fasta($subseq, "$transName Exon " . ($i+1) . " length=$len");
		
		if (defined $e2) {
			if ($strand eq '+') {
				$offset = $e1->{end} - $start + 1;
				$len = $e2->{start} - $e1->{end} - 1;
			}
			else {
				$offset = $e2->{end} - $start + 1;
				$len = $e1->{start} - $e2->{end} - 1;
			}
			die if ($len <= 0);
			
			my $subseq = substr($seq, $offset, $len);
			$subseq = reverse $subseq if ($REV_COMP);
			print fasta($subseq, "$transName Intron " . ($i+1) . " length=$len");		
		}
	}
	print "\n";
}

exit;

#-------------------------------------------------------------------------------
sub loadGene {
	my $filename = shift;
	my $geneName = shift;
	my ($geneStart, $geneEnd);
	my %exons;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $strand;
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
	       $strand = $tok[6];
		my $frame  = $tok[7];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'gene' and $type ne 'exon');
		
		# Parse gene name and transcript name from attributes field
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
			die "$attr" if (not defined $transName);
		
			push @{$exons{$transName}}, { start => $start, end => $end };
		}
	}
	close(INF);
	
	foreach my $transName (keys %exons) {
		if (not defined $strand or $strand eq '+') {
			$exons{$transName} = [ sort { $a->{start} <=> $b->{start} } @{$exons{$transName}} ];
		}
		else {
			$exons{$transName} = [ sort { $b->{start} <=> $a->{start} } @{$exons{$transName}} ];
		}
	}
	return ($geneStart, $geneEnd, $strand, \%exons);
}

sub loadFASTA {
	my $filename = shift;
	my $secName = shift; # optional
	my $out;
		
	open(F, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $line;
	my $name;
	while ($line = <F>) {
		chomp $line;
		if ($line =~ /^\>\s*(\S+)/) {
			last if (defined $name);
			next if (defined $secName and $secName ne $1);
			$name = $1;
		}
		elsif (defined $name) {
			my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
			$out .= $s if (defined $s);
		}
	}
	close(F);
	
	return $out;
}

sub fasta {
	my $in = shift;
	my $name = shift; # optional
	my $out;
	my $LINE_LEN = 80;
	
	$out .= ">$name\n" if (defined $name);
    while ($in) { # break up data into lines
    	$out .= substr($in, 0, $LINE_LEN) . "\n";
        substr($in, 0, $LINE_LEN) = '';
    }
    
    return $out;
}
