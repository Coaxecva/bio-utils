#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Report stats on specified pileup file.
# Author:	mdb
# Created:	1/27/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename
my $MIN_DEPTH = $ARGV[1];	# optional minimum required depth (default 6)
   $MIN_DEPTH = 6 if (not defined $MIN_DEPTH);

my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
   
my $DO_VARIANCE = 0;
my $DO_AGREEING = 0;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_stats.pl <pileup> [min_depth]\n" if ($#ARGV+1 < 1);

my $totalLines = 0;
my $totalBases = 0;
my $totalN = 0;
my $totalACGT = 0;
my $totalSNP = 0;
my $totalMinDepth = 0;
my $totalAgreeingMinDepth = 0;
my $totalDepth = 0;
my $totalAvgQual = 0;
my $totalPctAgree = 0;
my $totalIndels = 0;
my $totalRefSkips = 0;
my $minQual = 999;
my $maxQual = 0;

my @depths;
my @avgQuals;
my @avgAgrees;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

while (<INF>) {
	chomp;
	my @tok = split /\t/;
	
	$totalLines++;
	
	my ($refbase, $base, $depth, $pSeq, $pQual);
	if (@tok == 10) { # pileup with consensus format
		$refbase = $tok[2];
		$base    = $tok[3];
		$depth   = $tok[7];
		$pSeq    = \$tok[8];
		$pQual   = \$tok[9];
	}
	elsif (@tok == 6) { # mpileup format
		$refbase = $tok[2];
		$base    = '';
		$depth   = $tok[3];
		$pSeq    = \$tok[4];
		$pQual   = \$tok[5];		
	}
	else {
		die "Invalid pileup file format, line $totalLines, " . @tok . " tokens.\n";	
	}

	next if ($refbase eq '*' or length $base > 1); # ignore INDEL lines
	
	$totalBases++;
	if ($base eq 'N') {
		$totalN++;
		next;
	}
	#next if ($base !~ /[ACGT]/); # ignore ambiguous bases
	
	$totalACGT++;
	$totalSNP++ if ($base ne $refbase and $base ne '.' and $base ne ',');

	next if ($depth < $MIN_DEPTH);
	
	($depth, my $avgQual, my $isIndel, my $isRefSkip) = countHQBases($pSeq, $pQual);
	next if ($depth < $MIN_DEPTH);
	
	$totalIndels++ if ($isIndel);
	$totalRefSkips++ if ($isRefSkip);
	
	push @depths, $depth if ($DO_VARIANCE);
	
	$totalMinDepth++;
	$totalDepth += $depth;
	$totalAvgQual += $avgQual;
	
	push @avgQuals, $avgQual if ($DO_VARIANCE);
	
	if ($DO_AGREEING) {
		my $agreeing = countHQAgreeingBases($pSeq, $pQual);
		$totalAgreeingMinDepth++ if ($agreeing >= $MIN_DEPTH);
		my $pctAgree = $agreeing/$depth;
		$totalPctAgree += $pctAgree;
		
		push @avgAgrees, $pctAgree if ($DO_VARIANCE);
	}
}
close(INF);

print "Total lines: $totalLines\n";
print "Total bases: $totalBases\n";
print "Total N's: $totalN\n";
print "Total ACGT's: $totalACGT\n";
print "Total SNP's: $totalSNP\n";
print "Total @ " . $MIN_DEPTH . "x: $totalMinDepth\n";
print "Total agreeing @ " . $MIN_DEPTH . "x: $totalAgreeingMinDepth\n" if ($DO_AGREEING);

print "Average depth: " . ($totalDepth / $totalMinDepth) . ($DO_VARIANCE ? " (var=" . variance(\@depths) . ")" : '') . "\n";
print "Average quality: " . (($totalAvgQual / $totalMinDepth) - 33) . ($DO_VARIANCE ? " (var=" . variance(\@avgQuals) . ")" : '') . "\n";
print "Average %agreeing: " . ($totalPctAgree / $totalMinDepth) . " (var=" . variance(\@avgAgrees) . ")\n" if ($DO_AGREEING);

#print "Min quality: $minQual\n";
#print "Max quality: $maxQual\n";

print "Total indels: $totalIndels\n";
print "Total refskips: $totalRefSkips\n";

exit;

#-------------------------------------------------------------------------------
sub variance {
	my $pArray = shift;
	my $num = scalar @$pArray;
	return 0 if ($num == 0);
	
	# Compute average
	my $total = 0;
	foreach my $x (@$pArray) {
		$total += $x;
	}
	my $avg = $total / $num;
	
	# Compute variance
	my $var = 0;
	foreach my $x (@$pArray) {
		my $diff = $x - $avg;
		$var += $diff * $diff / $num;
	}
	
	return $var;
}
#-------------------------------------------------------------------------------
# Using substr is tiny bit faster than split
sub countHQBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my $count = 0;
	my $totalQual = 0;
	my $isIndel = 0;
	my $isRefSkip = 0;
	
	my ($i, $j);
	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
		my $c = substr($$pseq, $i, 1);
		print STDERR "error 1: $i $j $$pseq $$pqual\n" if (not defined $c);
		
		if ($c eq '>' or $c eq '<') { # reference skip 
			$j++; # mdb added 10/18/11
			$isRefSkip = 1;
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
			$isIndel = 1;
			$c = substr($$pseq, $i+1, 1);
			if ($c =~ /\d/) {
				$i++;
				my $c2 = substr($$pseq, $i+1, 1);
				if ($c2 =~ /\d/) {
					my $n = int($c)*10 + int($c2);
					$i += $n + 1;
				}
				else {
					$i += $c;
				}
			}
			next;
		}
		
		my $q = ord(substr($$pqual, $j++, 1));
		print STDERR "error 2: $i $j $$pseq $$pqual\n" if (not defined $q);
		if ($q >= $MIN_BASE_QUAL) {
			$count++;
			$totalQual += $q;
		}
	}
	die "error 3: $i $j $$pseq $$pqual" if ($i != length $$pseq or $j != length $$pqual);
	
	my $avg = 0;
	$avg = $totalQual/$count if ($count > 0);
	return ($count, $avg, $isIndel, $isRefSkip);
}
#sub countHQBases {
#	my $pseq = shift;
#	my $pqual = shift;
#	
#	my $count = 0;
#	my $totalQual = 0;
#	
#	my @as = split(//, $$pseq);
#	my @aq = unpack("C*", $$pqual);
#	
#	my ($i, $j);
#	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
#		my $c = $as[$i];
#		die "error 1: $i $j $$pseq $$pqual" if (not defined $c);
#		if ($c eq '>' or $c eq '<') { # reference skip
#			$j++;
#			next;
#		}
#		elsif ($c eq '$') { # end of read
#			next;
#		}
#		elsif ($c eq '^') { # start of read followed by encoded quality
#			$i++;
#			next;
#		}
#		elsif ($c eq '+' or $c eq '-') { # indel
#			$c = $as[$i+1];
#			if (isDigit($c)) {
#				$i++;
#				my $c2 = $as[$i+1];
#				if (isDigit($c2)) {
#					my $n = int("$c$c2");
#					$i += $n + 1;
#				}
#				else {
#					$i += $c;
#				}
#			}
#			next;
#		}
#		
#		my $q = $aq[$j++];
#		die "error 2: $i $j $$pseq $$pqual" if (not defined $q);
#		if ($q >= $MIN_BASE_QUAL and $c ne 'N') { # FIXME: really need to check for N?
#			$count++;
#			$totalQual += $q;
#		}
#	}
#	die "error 3: $i $j $$pseq $$pqual" if ($i != @as or $j != @aq);
#	
#	my $avg = 0;
#	$avg = $totalQual/$count if ($count > 0);
#	return ($count, $avg);
#}
#-------------------------------------------------------------------------------
sub countHQAgreeingBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my @as = split(//, $$pseq);
	my @aq = unpack("C*", $$pqual);
	my %baseCounts;
	
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
			if (isDigit($c)) {
				$i++;
				my $c2 = $as[$i+1];
				if (isDigit($c2)) {
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
sub isDigit {
	my $c = shift;
	return $c =~ /[0-9]/;
}
#-------------------------------------------------------------------------------
