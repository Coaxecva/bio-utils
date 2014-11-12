#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract sequence and depths in FASTA format from a pileup file.
# Author:	mdb
# Created:	11/17/10
#------------------------------------------------------------------------------
my $PREFIX = $ARGV[0];			# input pileup filename prefix
my $MIN_BASE_QUAL = $ARGV[1];	# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;		# scale for FASTQ encoding
my $MIN_DEPTH = $ARGV[2];		# minimum required depth
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_reduce.pl <prefix> <min_quality> <min_depth>\n" if ($#ARGV+1 < 3);

my $INPUT_FILE = "$PREFIX.pileup";
my $OUTPUT_FILE = $PREFIX . '_' . $ARGV[1] . 'q_' . $MIN_DEPTH . 'x.fastd';

my $inf;
open($inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $outf;
open($outf, '>', $OUTPUT_FILE) or 
	die("Error: cannot open file '$OUTPUT_FILE'\n");
	
my $lastRef;
my $seq;
my @depths;
my $start = 0;
my $end = 0;

my $line;
my @tok;
while( $line = <$inf> ) {
	chomp $line;
	@tok = split /\t/,$line;
	
	my $refbase = $tok[2];
	my $base = $tok[3];
	next if ($refbase eq '*' or length $base > 1); # ignore INDEL lines
	
	my $ref = $tok[0];
	my $pos = $tok[1];
	my $cov = countHQBases(\$tok[9]);
	
	next if ($cov < $MIN_DEPTH);
	
	if ($pos-$end > 1
		or not defined $lastRef
		or $ref ne $lastRef)
	{
		if (defined $lastRef) { # ignore start case
			my $len = $end - $start + 1;
			die "Error: sequence length mismatch for $lastRef:$start:$end $seq\n" 
				if ($len != length $seq);
			print_fasta($outf, "$lastRef,$start,$end", \$seq);
			my $d = pack("C*", @depths);
			print_fasta($outf, '', \$d);
		}
		$start = $pos;
		$lastRef = $ref;
		$seq = '';
		@depths = ();
	}
	
	$end = $pos;
	$seq .= $base;
	push @depths, min($cov+32, 255); # +32 instead of +33 because depth>0
}
close($inf);
close($outf);

exit;

#-------------------------------------------------------------------------------
sub print_fasta {
	my $fh = shift;		# file handle
	my $name = shift;	# fasta section name
	my $pIn = shift; 	# reference to section data
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
	print {$fh} ">$name\n";
    while ($ofs < $len) {
    	print {$fh} substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
}
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
sub min {
	my $x = shift;
	my $y = shift;
	
	return $x if ($x <= $y);
	return $y;	
}
