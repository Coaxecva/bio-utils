#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print lines from given pileup file that contain SNPs of a certain
#           minimum quality.  Excludes ambiguous calls.
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; 	# input pileup filename
#-------------------------------------------------------------------------------
my $MIN_DEPTH = 6;			# minimum HQ read coverage required
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality) phred score
   $MIN_BASE_QUAL += 33; 	# scale for FASTQ encoding
#-------------------------------------------------------------------------------
   
use warnings;
use strict;

die "Usage:  pileup_get_SNPs.pl <pileup>\n" if (@ARGV < 1);

open(my $inf, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $parsex = qr/^(\S+)\t(\S+)\t(\S+)\t(\S+)\t\S+\t\S+\t\S+\t(\S+)\t(\S+)\t(\S+)/;

while (my $line = <$inf>) {
	chomp $line;
	my ($ref, $pos, $refbase, $base, $depth, $seq, $qual) = $line =~ $parsex;
	next if ($refbase eq $base);  # skip if not a SNP
	next if ($depth < $MIN_DEPTH); # skip if low/hi qual depth is too low
	next if ($base eq 'N' or $refbase eq '*' or length $base > 1); # skip if reference skip
	next if ($base !~ /[ACGT]/); # skip if ambiguous

	$depth = countHQBases(\$seq, \$qual);
	if ($depth >= $MIN_DEPTH) {
		print $line . "\n";
	}
}
close($inf);

exit;
#-------------------------------------------------------------------------------

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
			$j++;
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
		if ($q >= $MIN_BASE_QUAL) {
			$count++;
		}
	}
	die "error 3: $i $j $$pseq $$pqual" if ($i != @as or $j != @aq);
	
	return $count;
}