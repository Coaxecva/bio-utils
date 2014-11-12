#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	9/21/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input pileup/VCF filename
my $CHROMOSOME = $ARGV[1];
my $POSITION = $ARGV[2];

my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33; 	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_line_info.pl <pileup> <chromosome> <position>\n" if ($#ARGV+1 < 3);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $parsex = qr/^(\S+)\t(\S+)/;

while (my $line = <$inf>) {
	my ($ref, $pos) = $line =~ $parsex;
	next if ($ref ne $CHROMOSOME or $pos ne $POSITION);
	print $line;
	
	my @tok = split("\t", $line);
	my ($refbase, $seq, $qual);
	$refbase = $tok[2];
	if (@tok == 6) { # new mpileup format
		$seq = $tok[4];
		$qual = $tok[5];		
	}
	else { # old pileup format
		$seq = $tok[8];
		$qual = $tok[9];
	}
	
	my $pAlleles = getAlleles($refbase, \$seq);
	my $pHQAlleles = getHQAlleles($refbase, \$seq, \$qual);
	
	print "All alleles:\n";
	foreach (sort keys %$pAlleles) {
		print "   $_:$pAlleles->{$_}\n";	
	}
	print "HQ alleles:\n";
	foreach (sort keys %$pHQAlleles) {
		print "   $_:$pHQAlleles->{$_}\n";	
	}
	
	last;
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
			$j++; # mdb added 10/18/11
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

sub getAlleles {
	my $refbase = shift;
	my $pSeq = shift;
	
	my %bases;
	my $count = 0;
	foreach my $b (split(//, $$pSeq)) {
		$b = $refbase if ($b eq '.' or $b eq ',');
		$b = uc($b);
		next if ($b =~ /[^ACGT]/);
		$bases{$b}++;
		$count++;
	}
	
	return ($count, \%bases);
}