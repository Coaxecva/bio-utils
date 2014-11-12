#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract gene sequences from pileup/VCF file into phylip files.
# Author:	mdb
# Created:	3/9/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup/VCF filename

my $ANNOT_FILE = '/data/genome/mus/combined.gtf';
my $ANNOT_TYPE = 'gene';	# should be lowercase
my %ANNOT_BIN_SZ = ( gene => 2000000, cds => 10000 );
# Note on binning:  bin should be at least 1/3 size of largest annotation.

my $MIN_DEPTH = 6;
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
#use strict; # doesn't work with cacheout
use FileCache;

die "Usage:  pileup_annot.pl <pileup>\n" if ($#ARGV+1 < 1);

my $pAnnot = loadGFF($ANNOT_FILE, $ANNOT_TYPE);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my @tok;
my %lastPos;

while (<INF>) {
	@tok = split /\t/;
	my $ref  = $tok[0];
	my $pos  = $tok[1];
	
	# Search all annotations
	my %found;
	foreach my $i (0, -1, 1) {
		my $bin = int($pos/$ANNOT_BIN_SZ{$ANNOT_TYPE}) + $i;
		foreach my $a (@{$pAnnot->{$ref}{$bin}}) {
			my $name = $a->{name};
			next if (defined $found{$name});

			if ($pos >= $a->{start} and $pos <= $a->{end}) { # overlapping
				$found{$name}++;
				my $file = "$name.phylip";
				
				if (not defined $lastPos{$name}) {
					cacheout $file;
					print $file "$name\t";
					$lastPos{$name} = $a->{start};
				}
				
				my $gap = $pos - $lastPos{$name} - 1;
				print $file 'N' x $gap if ($gap > 0);
				
				my $refbase = $tok[2];
				my $base = $tok[3];
				my $depth = $tok[7];
				
				if (#$depth < $MIN_DEPTH or 
					$refbase eq '*' or length $base > 1 or 
					$base !~ /[ACGT]/ #or 
					#countHQBases(\$tok[8], \$tok[9]) < $MIN_DEPTH
					)
				{
					$base = 'N';
				}

				print $file $base;
				$lastPos{$name} = $pos;
				
				# can't break here b/c of potential overlapping annotations
			}
		}
	}
}
close(INF);

foreach my $ref (keys %$pAnnot) {
	foreach my $bin (keys %{$pAnnot->{$ref}}) {
		foreach my $a (@{$pAnnot->{$ref}{$bin}}) {
			next if (not defined $lastPos{$a->{name}});
			my $gap = $a->{end} - $lastPos{$a->{name}};
			if ($gap > 0) {
				my $file = "$a->{name}.phylip";
				print $file 'N' x $gap;
			}
		}
	}
}

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
		print STDERR "error 1: $i $j $$pseq $$pqual\n" if (not defined $c);
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
		print STDERR "error 2: $i $j $$pseq $$pqual\n" if (not defined $q);
		if ($q >= $MIN_BASE_QUAL and $c ne 'N') { # FIXME: really need to check for N?
			$count++;
		}
	}
	
	return $count;
}
#-------------------------------------------------------------------------------
sub loadGFF {
	my $filename = shift;
	my $typeToLoad = shift;
	my $pout;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my @tok;
	while (<INF>) {
		chomp;
		@tok = split /\t/;
		my $ref   = $tok[0];
		my $type  = lc($tok[2]);
		my $start = $tok[3];
		my $end   = $tok[4];
		my $attr  = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne $typeToLoad);
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding entry due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
#		my ($name) = $attr =~ /transcript_name \"(\S+)\";/;
		
		my $bin = int($start/$ANNOT_BIN_SZ{$type});
		push @{ $pout->{$ref}{$bin} }, { name => $name, start => $start, end => $end };
	}
	close(INF);

	return $pout;
}
