#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Report stats on specified VCF file.
# Author:	mdb
# Created:	1/31/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename
my $MIN_DEPTH = $ARGV[1];	# optional minimum required depth (default 6)
   $MIN_DEPTH = 6 if (not defined $MIN_DEPTH);
my $MIN_BASE_QUAL = 40;		# definition of *consensus* HQ (High Quality)
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  vcf_stats.pl <file> [min_depth]\n" if ($#ARGV+1 < 1);

my $totalBases = 0;
my $totalMinDepth = 0;
my $totalDepth = 0;
my $totalQual = 0;
my $minQual = 999999;
my $maxQual = 0;
my $multiAllelic = 0;
my %bcounts;

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my @tok;
while (<INF>) {
	next if (/^#/);
	@tok = split /\t/;
	
	$totalBases++;
	
	#next if ($tok[7] =~ /INDEL;/);
	next if (index($tok[7], 'INDEL') >= 0);
	
	my ($depth) = $tok[7] =~ /DP=(\d+)/;
	next if ($depth < $MIN_DEPTH);
	
	my $refbase = $tok[3];
	my $base = $tok[4];
	next if (length $base > 1);
	$base = $refbase if ($base eq '.');
	if (length $base == 1) { $bcounts{$base}++; }
	else { $multiAllelic++; }
	print "$tok[0] $tok[1] $base\n" if (length $base > 1);
	#next if ($base !~ /[\.ACGT]/); # ignore ambiguous bases      # FIXME for alleles
	
	my $qual = $tok[5];
	$minQual = $qual if ($qual < $minQual);
	$maxQual = $qual if ($qual > $maxQual);
	next if ($qual < $MIN_BASE_QUAL);
	
	$totalMinDepth++;
	$totalDepth += $depth;
	$totalQual += $qual;
}
close(INF);

print "Total bases: $totalBases\n";
print "Total ACGT @ " . $MIN_DEPTH . "x : $totalMinDepth\n";
print "Average depth: " . ($totalDepth / $totalMinDepth) . "\n";
print "Average quality: " . ($totalQual / $totalMinDepth) . "\n";
print "Min quality: $minQual\n";
print "Max quality: $maxQual\n";
print "Multi-allelic: $multiAllelic\n";
print "Base counts:\n";
print "   $_ $bcounts{$_}\n" foreach (sort keys %bcounts);

exit;

#-------------------------------------------------------------------------------
