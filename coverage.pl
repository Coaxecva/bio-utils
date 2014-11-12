#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	10/15/10
#-------------------------------------------------------------------------------
die "Usage: coverage.pl [-a] <prefix> <min_qual> <min_depth> [min_depth2 ...]\n" if ($#ARGV+1 < 3);
my $REQUIRE_AGREEING = shift @ARGV if ($ARGV[0] eq '-a');
my $PREFIX = $ARGV[0]; 			# e.g. "subset4a" for subset4a.pileup
my $MIN_BASE_QUAL = $ARGV[1];	# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33; 		# scale for FASTQ encoding
my @MIN_CONT_COV = sort {$a<=>$b} splice @ARGV,2; # min HQ coverage required in region
#-------------------------------------------------------------------------------
my $INPUT_PILEUP_FILE = "$PREFIX.pileup";
my $DO_SNPS = 0;
#-------------------------------------------------------------------------------

use warnings;
use strict;

my $MIN_DEPTH = $MIN_CONT_COV[0];

open(PILEUP, $INPUT_PILEUP_FILE) or 
	die("Error: cannot open file '$INPUT_PILEUP_FILE'\n");
	
my %fh;
foreach my $depth (@MIN_CONT_COV) {
	my $filename = $PREFIX . '_' . $ARGV[1] . 'q_' . $depth . 'x' . ($REQUIRE_AGREEING ? 'A' : '') . '.coverage';
	open($fh{$depth}, '>', $filename) or 
		die("Error: cannot open file '$filename'\n");
}

if ($DO_SNPS) {
	my $filename = $PREFIX . '_' . $ARGV[1] . 'q_' . $MIN_DEPTH . 'x' . ($REQUIRE_AGREEING ? 'A' : '') . '.snp';
	open(SNP, '>', $filename) or 
		die("Error: cannot open file '$filename'\n");
}

my %lastRef;
my %start;
my %end;

my $line;
my @tok;
while ($line = <PILEUP>) {
	chomp $line;
	@tok = split /\t/, $line;
	my $depth = $tok[7];
	
	if ($depth >= $MIN_DEPTH) {
		$depth = ($REQUIRE_AGREEING ? countHQAgreeingBases(\$tok[8], \$tok[9]) : countHQBases(\$tok[9]));
		
		my $ref     = $tok[0];
		my $pos     = $tok[1];
		my $refbase = $tok[2];
		my $base    = $tok[3];
			
		next if ($refbase eq '*' or length $base > 1); # ignore INDEL lines
		
		foreach my $m (@MIN_CONT_COV) { # ascending order
			next if ($depth < $m);
			
			if ((defined $end{$m} and $pos-$end{$m} > 1)
				or not defined $lastRef{$m}
				or $ref ne $lastRef{$m})
			{
				print {$fh{$m}} "$lastRef{$m}\t$start{$m}\t$end{$m}\t$m\n" if (defined $lastRef{$m});
				$start{$m} = $end{$m} = $pos;
				$lastRef{$m} = $ref;
			}
			else {
				die "Error: repeated position $ref:$pos\n" if ($pos > 0 and defined $end{$m} and $pos-$end{$m} == 0);
				$end{$m} = $pos;
			}
			
			if ($DO_SNPS and $m == $MIN_DEPTH and $base ne $refbase) {
				print SNP "$lastRef{$m}\t$pos\t$depth\t$refbase\t$base\t$tok[8]\t$tok[9]\n";
			}
		}
	}
}

close(PILEUP);
close(SNP) if ($DO_SNPS);
close($_) foreach (values %fh);

exit;

#-------------------------------------------------------------------------------
sub countHQBases {
	my $pQual = shift; # reference to array of packed quality values
	
	my $count = 0;
	foreach my $c (unpack("C*", $$pQual)) {
		$count++ if ($c >= $MIN_BASE_QUAL);
	}
	
	return $count;
}
#-------------------------------------------------------------------------------
sub countHQAgreeingBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my @as = split(//, $$pseq);
	my @aq = unpack("C*", $$pqual);
	my %baseCounts;
	
	for (my ($i, $j) = (0, 0);  $i < length $$pseq;  $i++) {
		my $c = $as[$i];
		if ($c eq '$') {
			next;
		}
		elsif ($c eq '^') {
			$i++;
			next;
		}
		elsif ($c eq '+' or $c eq '-') {
			$i++;
			$c = $as[$i];
			$i += $c if (isDIGIT($c));
			next;
		}
		
		my $q = $aq[$j++];
		if ($q >= $MIN_BASE_QUAL and $c ne 'N') {
			$c = '.' if ($c eq ','); # reverse strand
			$c = uc($c);
			$baseCounts{$c}++;
		}
	}
	
	my $max = 0;
	foreach my $b (keys %baseCounts) {
		$max = $baseCounts{$b} if ($baseCounts{$b} > $max);
	}
	
	return $max;
}
#-------------------------------------------------------------------------------
sub getHQAgreeingBases {
	my $seq = shift;
	my $qual = shift;
	
	my @as = split(//, $seq);
	my @aq = unpack("C*", $qual);
	my %bCounts;
	my $total = 0;
	
	for (my ($i, $j) = (0, 0);  $i < length $seq;  $i++) {
		my $c = $as[$i];
		if ($c eq '$') {
			next;
		}
		elsif ($c eq '^') {
			$i++;
			next;
		}
		elsif ($c eq '+' or $c eq '-') {
			$i++;
			$c = $as[$i];
			$i += $c if (isDIGIT($c));
			next;
		}
		
		my $q = $aq[$j++];
		if ($q >= $MIN_BASE_QUAL and $c ne 'N') {
			$c = '.' if ($c eq ','); # reverse strand
			$c = uc($c);
			$bCounts{$c}++;
			$total++;
		}
	}
	
	my @out;
	foreach my $b (sort {$bCounts{$b} <=> $bCounts{$a}} keys %bCounts) {
		if ($bCounts{$b}/$total > 0.1) {
			push @out,$b;
			push @out,$bCounts{$b};
		}
	}
	
	return \@out;
}
#-------------------------------------------------------------------------------
