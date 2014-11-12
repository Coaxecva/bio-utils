#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract sequence for specified region and print to stdout in 
#           fasta format.
# Author:	mdb
# Created:	5/17/11
#------------------------------------------------------------------------------
my $INPUT_FILE	= $ARGV[0];	# input pileup filename
my $LOCATION	= $ARGV[1];	# chromosome:start:end
#-------------------------------------------------------------------------------
my $MIN_DEPTH = 6;
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
my $ASCII_SCALE = 33;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_get_region.pl <pileup> <chr:start:end>\n" if ($#ARGV+1 < 2);

my ($chr, $start, $end) = split(/:/, $LOCATION);
my $revComp = 0;
if ($end < $start) {
	$revComp = 1;
	($start, $end) = ($end, $start);
}

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $seq;
my $lastPos = $start-1;
	
while (<$fh>) {
	my ($ref, $pos) = $_ =~ /^(\w+)\t(\d+)/;
	next if ($ref ne $chr or $pos < $start or $pos > $end);
    
    chomp;	
	my @tok = split /\t/;

	my $refbase = $tok[2];
	my $base = $tok[3];
	next if ($base eq 'N' or $refbase eq '*' or length $base > 1);
	
	my $depth = countHQBases(\$tok[8], \$tok[9]);
	next if ($depth < $MIN_DEPTH);
	
    # Fill gaps with N's
    my $gap = $pos - $lastPos - 1;
    if ($gap > 0) {
	    $seq .= 'N' x $gap;
    }
    		
    $seq .= $base;
    $lastPos = $pos;
    last if ($pos == $end);
}
close($fh);

# Fill end gap with N's
my $gap = $end - $lastPos;
if ($gap > 0) {
	$seq .= 'N' x $gap;
}

# Print sequence and quality to stdout
reverseComplement(\$seq) if ($revComp);
print_fasta($LOCATION, \$seq);

#debug:
#print length($seq) . "\n";
#my $pos = $START;
#foreach my $c (split(//,$seq)) {
#	print "$pos\t$c\n";
#	$pos++;
#}

exit;

#-------------------------------------------------------------------------------
sub print_fasta {
	my $name = shift;	# fasta section name
	my $pIn = shift; 	# reference to section data
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
	print ">$name\n";
    while ($ofs < $len) {
    	print substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
}

sub reverseComplement {
	my $p = shift; # reference to string
	
	$$p =~ tr/[AGCTBDHKMRSWVY]/[TCGAVHDMKYSWBR]/;
	$$p = reverse($$p);
}

sub countHQBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my $count = 0;
	
	my @as = split(//, $$pseq);
	my @aq = unpack("C*", $$pqual);
	
	my ($i, $j);
	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
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
			if ($c =~ /\d/) {
				$i++;
				my $c2 = $as[$i+1];
				if ($c2 =~ /\d/) {
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
			$count++;
		}
	}
	die "error 3: $i $j $$pseq $$pqual" if ($i != @as or $j != @aq);
	
	return $count;
}
