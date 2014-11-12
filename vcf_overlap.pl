#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print lines in vcf2 that overlap vcf1 (ignoring ambiguous).
# Author:	mdb
# Created:	2/7/11
#------------------------------------------------------------------------------
my $INPUT_VCF_1 = $ARGV[0];		# input VCF filename
my $INPUT_VCF_2 = $ARGV[1];		# input VCF filename
my $MIN_BASE_QUAL = $ARGV[2];	# definition of *consensus* HQ (High Quality)
   $MIN_BASE_QUAL = 40 if (not defined $MIN_BASE_QUAL);
my $MIN_DEPTH = 6;		# minimum required HQ depth
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_overlap.pl <vcf1> <vcf2> [min_depth]\n" if ($#ARGV+1 < 2);

my %bases;

my $line;
my @tok;

open(INF, $INPUT_VCF_1) or 
	die("Error: cannot open file '$INPUT_VCF_1'\n");
while (<INF>) {
	next if (/^#/);
	@tok = split /\t/;
	
	my $qual = $tok[5];
	next if ($qual < $MIN_BASE_QUAL);
	
	my $base = $tok[4];
	next if (length $base > 1); # ignore ambiguous bases
	
	my $info = $tok[7];
	next if (index($info, 'INDEL') >= 0);
	
	my ($depth) = $info =~ /DP=(\d+)/;
	next if ($depth < $MIN_DEPTH);
	
	my $ref = $tok[0];
	my $pos = $tok[1];
	$bases{$ref}{$pos} = 1;
}
close(INF);

open(INF, $INPUT_VCF_2) or 
	die("Error: cannot open file '$INPUT_VCF_2'\n");
while ($line = <INF>) {
	next if ($line =~ /^#/);
	@tok = split /\t/,$line;
	
	my $ref = $tok[0];
	my $pos = $tok[1];
	next if (not defined $bases{$ref}{$pos});
	
	my $qual = $tok[5];
	next if ($qual < $MIN_BASE_QUAL);
	
	my $base = $tok[4];
	next if (length $base > 1); # ignore ambiguous bases
	
	my $info = $tok[7];
	next if (index($info, 'INDEL') >= 0);

	my ($depth) = $info =~ /DP=(\d+)/;
	next if ($depth < $MIN_DEPTH);
	
	print $line;
}
close(INF);

exit;

#-------------------------------------------------------------------------------
