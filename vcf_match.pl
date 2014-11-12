#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count matching bases between VCF files,
#           save matches/mismatches to respective files for second VCF file.
#           Doesn't check for quality/depth (assumes prefiltering).
# Author:	mdb
# Created:	2/7/11
#------------------------------------------------------------------------------
my $INPUT_VCF_1 = $ARGV[0];	# input VCF filename
my $INPUT_VCF_2 = $ARGV[1];	# input VCF filename
my $SUPPRESS_OUTPUT = 1; 	# don't create output files, just print summary
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  vcf_match.pl <vcf1> <vcf2>\n" if ($#ARGV+1 < 2);

if (not $SUPPRESS_OUTPUT) {
	open(MATCH, ">$INPUT_VCF_2.match") or die("Error: cannot open output file\n");
	open(MISMATCH, ">$INPUT_VCF_2.mismatch") or die("Error: cannot open output file\n");
}

my %bases;
my $line;
my @tok;

my $total = 0;
my $matches = 0;
my $mismatches = 0;
my $multiAllelic1 = 0;
my $multiAllelic2 = 0;
my $matchMultiAllelic = 0;
my $mismatchMultiAllelic = 0;

open(INF, $INPUT_VCF_1) or 
	die("Error: cannot open file '$INPUT_VCF_1'\n");
while (<INF>) {
	@tok = split /\t/;
	my $ref = $tok[0];
	my $pos = $tok[1];
	my $refbase = $tok[3];
	my $base = $tok[4];
	
	$multiAllelic1++ if (length $base > 1);
	#next if (length $base > 1);
	
	$base = $refbase if ($base eq '.');
	$bases{$ref}{$pos} = $base;
}
close(INF);

open(INF, $INPUT_VCF_2) or 
	die("Error: cannot open file '$INPUT_VCF_2'\n");
while ($line = <INF>) {
	@tok = split /\t/,$line;
	my $ref = $tok[0];
	my $pos = $tok[1];
	
	my $base1 = $bases{$ref}{$pos};
	if (defined $base1) {
		$total++;
		
		my $refbase = $tok[3];
		my $base2 = $tok[4];
		$multiAllelic2++ if (length $base2 > 1);
		#next if (length $base2 > 1);
		$base2 = $refbase if ($base2 eq '.');
		
		if (testBases($base1, $base2)) {
			$matches++;
			$matchMultiAllelic++ if (length $base1 > 1 or length $base2 > 1);
			print MATCH $line if (not $SUPPRESS_OUTPUT);
		}
		else {
			$mismatches++;
			$mismatchMultiAllelic++ if (length $base1 > 1 or length $base2 > 1);
			print MISMATCH $line if (not $SUPPRESS_OUTPUT);
			#print "$ref $pos $base1 $base2\n";
		}
	}
}
close(INF);

if (not $SUPPRESS_OUTPUT) {
	close(MATCH);
	close(MISMATCH);
}

print "Total common bases: $total\n";
print "Matches: $matches\n";
print "Mismatches: $mismatches\n";
print "Multi-allelic 1: $multiAllelic1\n";
print "Multi-allelic 2: $multiAllelic2\n";
print "Multi-allelic matches: $matchMultiAllelic\n";
print "Multi-allelic mismatches: $mismatchMultiAllelic\n";

exit;
#-------------------------------------------------------------------------------

sub testBases {
	my $bases1 = shift;
	my $bases2 = shift;
	
	my @a1;
	my @a2;
	@a1 = split(/,/, $bases1) if (length $bases1 > 1);
	@a2 = split(/,/, $bases2) if (length $bases2 > 1);
	
	if (@a1 > 0) {
		if (@a2 > 0) {
			foreach my $b1 (@a1) {
				foreach my $b2 (@a2) {
					return 1 if ($b1 eq $b2);
				}
			}
		}
		else {
			foreach my $b1 (@a1) {
				return 1 if ($b1 eq $bases2);
			}
		}
	}
	elsif (@a2 > 0) {
		foreach my $b2 (@a2) {
			return 1 if ($b2 eq $bases1);
		}
	}
	else {
		return ($bases1 eq $bases2);	
	}
	
	return 0;
}
