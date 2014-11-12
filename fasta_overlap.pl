#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Reports the no. of overlapping bases between sequences in a 
#           FASTA/PHYLIP file.
# Author:	mdb
# Created:	5/16/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];  # input file name 
# -----------------------------------------------------------------------------

use warnings;
use strict;
use List::Util qw(first);

die "Usage:  fasta_overlap.pl <input_filename>\n" if ($#ARGV+1 < 1);

my ($pSeq, $len) = loadFASTAorPHYLIP($INPUT_FILE);
my ($overlap, $maxCont, $covered) = countOverlappingBases($pSeq);
my ($pSites, $pPoly) = getSites($pSeq, ['sanger_WSB', 'merged_PWK']);

print "Length: $len\n";
print "Overlap: $overlap (" . sprintf("%.2f", 100*$overlap/$len) . "%)\n";
print "Max continuous: $maxCont\n";
print "Covered: $covered (" . sprintf("%.2f", 100*$covered/$len) . "%)\n";
print "SNPs: " . (keys %$pPoly) . " out of " . (keys %$pSites) . "\n";

exit;

#-------------------------------------------------------------------------------
sub getSites {
	my $pSeq = shift; 				# ref to sequences hashed by name
	my $pSpecies = shift;
	die if (keys %$pSeq == 0);
	
	$pSpecies = [keys %$pSeq] if (not defined $pSpecies);
	
	my $len = length( first {defined($_)} values %$pSeq );
	
	my (%sites, %poly, %fixed);#, %freq, %syn, %nonsyn); # sites by fold
	for (my $pos = 0;  $pos < $len;  $pos += 3) { # for each codon
		# Get codon sequences at this position
		my %codons;
		foreach my $name (@$pSpecies) {
			my $codon = substr($pSeq->{$name}, $pos, 3);
			$codon .= 'N' x (3-(length $codon)) if (length $codon < 3); # pad to codon boundary
			$codons{$name} = $codon;
		}
		
		for my $i (0, 1, 2) { # for each site within codon
			my $pos2 = $pos + $i;
			
			# Determine polymorphism within subspecies
			my %bases;
			my $numBases = 0;
			my $missing = 0;
			foreach my $name (@$pSpecies) {
				my $b = substr($codons{$name}, $i, 1);
				if ($b ne 'N') {
					$numBases++;
					$bases{$b}++; 
				}
				else {
					$missing++;	
				}
			}
			
			# Exclude if missing bases
			if ($missing > 0) {
				goto NEXT_SITE;
			}
			
			# Record site
			$sites{$pos2}++;
			
			# Determine polymorphism / fixed difference
			if (keys %bases > 1) { # Polymorphic within subspecies
				# Record polymorphism
				$poly{$pos2}++;
				print "$pos2\n";
			}
			NEXT_SITE: # skip site
		}
		NEXT_CODON: # skip codon
	}
	
	return (\%sites, \%poly);
}

sub loadFASTAorPHYLIP {
	my $filename = shift;
	my %out;
		
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $name;
	while (my $line = <$fh>) {
		chomp $line;
		if ($line =~ /^\>(\S+)/) { # FASTA header
			$name = $1;
			die "Error: sequences with same name in input file\n" if (defined $out{$name});
		}
		elsif ($line =~ /^(\S+)\s+(\S+)/) { # PHYLIP header & data
			$name = $1;
			die "Error: sequences with same name in input file\n" if (defined $out{$name});
			$out{$name} = $2;
		}
		else { # FASTA data
			die "loadFASTA: parse error" if (not defined $name);
			my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
			$out{$name} .= $s if (defined $s);
		}
	}
	close($fh);
	
	my $len;
	foreach $name (keys %out) {
		$len = length $out{$name} if (not defined $len);
		die "Error: all sequences are not the same length\n" if ($len != length $out{$name});
	}
	
	return (\%out, $len);
}

sub countOverlappingBases {
	my $pSeq = shift; # ref to hash of strings of the same length, N's for gaps
	
	# Create composite sequence string using bitwise op
	my $x;
	foreach my $s (values %$pSeq) {
		$s =~ tr/N/\x20/; # replace N's with spaces
		$x |= $s;
	}
	
	my $overlap = () = $x =~ /[A-Z\_\[\]\^]/g;
	my $covered = () = $x =~ /[^\x20]/g;
	
	my $maxCont = 0;
	while ($x =~ /([A-Z\_\[\]\^]+)/g) {
		my $len = length $1;
    	$maxCont = $len if $len > $maxCont;
	}
	
	# Replace spaces with N's
	foreach my $s (values %$pSeq) {
		$s =~ tr/\x20/N/; # replace spaces with N's
	}
	
	return ($overlap, $maxCont, $covered);
}
