#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract sequence for specified gene and print to stdout in 
#           phylip format with read depths.
# Author:	mdb
# Created:	5/17/11
#------------------------------------------------------------------------------
my $INPUT_FILE	= $ARGV[0];	# input pileup filename
my $GENE_NAME	= $ARGV[1];	# name of gene to extract
#-------------------------------------------------------------------------------
my $ANNOT_FILE = '/data/genome/mus/combined.gtf';
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
my $ASCII_SCALE = 33;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_get_gene.pl <input_filename> <gene_name>\n" if ($#ARGV+1 < 2);

my ($chr, $start, $end) = loadGFFGene($ANNOT_FILE, $GENE_NAME);
die "Gene '$GENE_NAME' not found\n" if (not defined $chr);

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $seq;
my @depths;
my $lastPos = $start-1;
	
while (<$fh>) {
	my ($ref, $pos) = $_ =~ /^(\w+)\t(\d+)/;
	next if ($ref ne $chr or $pos < $start or $pos > $end);
    
    chomp;	
	my @tok = split /\t/;
	
	my $refbase = $tok[2];
	my $base = $tok[3];
	next if ($refbase eq '*' or length $base > 1); # ignore INDEL lines
	
	my $depth = countHQBases(\$tok[8], \$tok[9]);
	
    # Fill gaps with N's
    my $gap = $pos - $lastPos - 1;
    if ($gap > 0) {
	    $seq .= 'N' x $gap;
	    push @depths,(0+$ASCII_SCALE) for (1..$gap);
    }
    		
    $seq .= $base;
    push @depths, min($depth+$ASCII_SCALE, 255);
    
    $lastPos = $pos;
    last if ($pos == $end);
}
close($fh);

# Fill end gap with N's
my $gap = $end - $lastPos;
if ($gap > 0) {
	$seq .= 'N' x $gap;
	push @depths,(0+$ASCII_SCALE) for (1..$gap);
}

# Print sequence and quality to stdout
print "$GENE_NAME\t$seq\t" . pack("C*", @depths);

#debug:
#print length($seq) . "\n";
#my $pos = $START;
#foreach my $c (split(//,$seq)) {
#	print "$pos\t$c\n";
#	$pos++;
#}

exit;

#-------------------------------------------------------------------------------
sub countHQBases {
	my $pseq = shift;
	my $pqual = shift;
	
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
		if ($q >= $MIN_BASE_QUAL and $c ne 'N') { # FIXME: really need to check for N?
			$count++;
		}
	}
	
	return $count;
}

sub loadGFFGene {
	my $filename = shift;
	my $geneName = shift;
	
	die if (not defined $filename or not defined $geneName);
	
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while (<$fh>) {
		chomp;
		my @tok = split(/\t/);
		my $chr    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'gene');
		
		# Validate coordinates
		if ($start > $end) {
			#print "Warning: discarding entry due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		next if (not defined $name or $name ne $geneName);
		
		# Extract chromosome number from reference name
		if ($chr =~ /chr(\w+)/) {
			$chr = $1;
		}
		
		close($fh);
		return ($chr, $start, $end);
	}
	
	close($fh);
	return;
}

sub min {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x <= $y);
	return $y;
}
