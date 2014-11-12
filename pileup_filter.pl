#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	12/23/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename prefix
#-------------------------------------------------------------------------------
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
my $MIN_DEPTH = 6;
my $SEQ_COL = 4;
my $QUAL_COL = 5;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_filter.pl <filename>\n" if ($#ARGV+1 < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $line;
my @tok;
while( $line = <INF> ) {
	chomp $line;
	@tok = split /\t/,$line;
	
	my $refbase = $tok[2];
	my $base = $tok[3];
	next if ($refbase eq '*' or length $base > 1); # ignore INDEL lines
	
	my $ref = $tok[0];
	my $pos = $tok[1];
	my $cov = countHQBases(\$tok[$SEQ_COL], \$tok[$QUAL_COL]);
	
	next if ($cov < $MIN_DEPTH);
	
	#print "$ref\t$pos\t$refbase\t$base\t$cov\n";
	print "$line\n";
}
close(INF);

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
#sub countHQBases {
#	my $pQual = shift; # reference to array of packed quality values
#	
#	my $count = 0;
#	foreach my $c (unpack("C*", $$pQual)) {
#		$count++ if ($c >= $MIN_BASE_QUAL);
#	}
#	
#	return $count;
#}


sub isDigit {
	my $c = shift;
	return $c =~ /[0-9]/;
}
