#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract sequence for all chromosomes and print as fasta to stdout.
#           *** REPLACED BY pileup_get_chr_C.pl, USE IT INSTEAD ***
# Author:	mdb
# History:
# 	1/25/12	Created
# 	3/15/12	Tested, equivalent to pileup_get_chr.pl
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename
my $CHROMOSOME = $ARGV[1];	# optional chromosome number
#-------------------------------------------------------------------------------
my $MIN_DEPTH = 6;			# minimum HQ read depth
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/workspace/Work";
use Pileup qw{countHQBases};

die "Usage:  pileup_get_chr.pl <pileup> [chromosome]\n" if (@ARGV < 1);

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $seq;
my $lastChr;
my $lastPos = 0;

while (<$fh>) {
	if (defined $CHROMOSOME) {
		my ($chr) = $_ =~ /^(\S+)/;
		next if ($chr ne $CHROMOSOME);	
	}
	
    chomp;
	my @tok = split /\t/;

	my $refbase = $tok[2];
	my $base = $tok[3];
	next if ($base eq 'N' or $refbase eq '*' or length $base > 1); # ignore INDEL lines and refskips
	
	my $depth = countHQBases(\$tok[8], \$tok[9]);
	next if ($depth < $MIN_DEPTH);
	
	my $chr = $tok[0];
	my $pos = $tok[1];
	
	# Print header
	if (not defined $lastChr or $chr ne $lastChr) {
		if (defined $seq and length $seq > 0) {
			print_fasta(\$seq); # print full lines
			print "$seq\n"; 	# print remainder
			$seq = '';
		}
		
		print ">$chr\n";
		$lastChr = $chr;
		$lastPos = 0;
	}
	
    # Fill gaps with N's
    my $gap = $pos - $lastPos - 1;
    if ($gap > 0) {
	    $seq .= 'N' x $gap;
    }
    
    $seq .= $base;
    $lastPos = $pos;
    
    # Dump sequence to stdout
    while (length $seq >= 1000) {
    	print_fasta(\$seq);
    }
}
close($fh);

# Flush end of seq
print_fasta(\$seq); # print full lines
print "$seq\n"; 	# print remainder

# Fill end gap with N's
#my $gap = $end - $lastPos;
#if ($gap > 0) {
#	$seq .= 'N' x $gap;
#}

exit;

#-------------------------------------------------------------------------------
sub print_fasta {
	my $pIn = shift; 	# reference to string
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
    while ($ofs+$LINE_LEN < $len) {
    	print substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
    substr($$pIn, 0, $ofs) = '';
}

