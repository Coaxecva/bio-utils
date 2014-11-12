#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print lines from given pileup file that have refskips.
# Author:	mdb
# Created:	10/12/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; 	# input pileup/VCF filename
my $MIN_DEPTH = 6;

my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33; 	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

die "Usage:  pileup_SNPs.pl <pileup>\n" if ($#ARGV+1 < 1);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $parsex = qr/^(\S+)\t(\S+)\t(\S+)\t(\S+)\t\S+\t\S+\t\S+\t(\S+)\t(\S+)\t(\S+)/;

while (my $line = <$inf>) {
	chomp $line;
	my ($ref, $pos, $refbase, $base, $depth, $seq, $qual) = $line =~ $parsex;
#	next if (not defined $CHROMOSOMES{$ref});
	next if ($depth < $MIN_DEPTH or $base eq 'N' or $refbase eq '*' or length $base > 1);
	
	if ($seq =~ /[\>\<]/) {
		my ($realDepth, $pAlleles) = getHQAlleles($refbase, \$seq, \$qual);
		if ($realDepth >= $MIN_DEPTH) {
			print "$line\n";
		}
	}
}
close($inf);


exit;

#-------------------------------------------------------------------------------
sub getHQAlleles {
	my $refbase = shift;
	my $pseq = shift;
	my $pqual = shift;
	
	my %bases;
	my $count = 0;
	
	my @as = split(//, $$pseq);
	my @aq = unpack("C*", $$pqual);
	
	for (my ($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
		my $c = $as[$i];
		die "error 1: $i $j $$pseq $$pqual\n" if (not defined $c);
		if ($c eq '>' or $c eq '<') { # reference skip 
			$j++;
			next;
		}
		elsif ($c eq '$') { # end of read
			next;
		}
		elsif ($c eq '^') { # start of read followed by encoded quality
			$i++;
			next;
		}
		elsif ($c eq '+' or $c eq '-') { # indel
			$c = $as[$i+1];
			if ($c =~ /[0-9]/) {
				$i++;
				my $c2 = $as[$i+1];
				if ($c2 =~ /[0-9]/) {
					my $n = int("$c$c2");
					$i += $n + 1;
				}
				else {
					$i += $c;
				}
			}
			next;
		}
		
		my $q = $aq[$j++];
		die "error 2: $i $j $$pseq $$pqual\n" if (not defined $q);
		if ($q >= $MIN_BASE_QUAL and $c ne 'N') { # FIXME: really need to check for N?
			$c = $refbase if ($c eq '.' or $c eq ',');
			$c = uc($c);
			next if ($c =~ /[^ACGT]/);
			$bases{$c}++;
			$count++;
		}
	}
	
	return ($count, \%bases);
}