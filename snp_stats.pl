#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Display stats on SNPs in input file.
# Author:	mdb
# Created:	1/25/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $ANNOT_BIN_SZ = 2000000;
my $READ_BIN_SZ = 500000;
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

$| = 1;

die "Usage:  snp_stats.pl <pileup>\n" if ($#ARGV+1 < 1);

my $pSNP = loadSNP($INPUT_FILE);

my @annot_types = ('gene', 'cds');
my $pAnnot = loadGFF('/data/genome/mus/combined.gtf', \@annot_types);

my $pJunc = loadJunctionBED('./junctions.bed');

my $sam = Bio::DB::Sam->new(-bam => './accepted_hits.filtered.bam');

my $total = 0;
my $coding = 0;
my $genic = 0;
my $junc = 0;
my ($endOfRead1, $endOfRead3, $endOfRead5) = (0, 0, 0);
my ($startOfRead1, $startOfRead3, $startOfRead5) = (0, 0, 0);
my $notWithin10 = 0;

foreach my $ref (sort keys %$pSNP) {
	print "$ref ";
	
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	my %reads;
	foreach my $r (@matches) {
		my $name  = $r->seq_id;
		my $start = $r->start;
		my $end   = $r->end;
		die "Invalid coords $start:$end\n" if ($end < $start);
		push @{ $reads{$name}{int($start/$READ_BIN_SZ)} }, { start => $start, end => $end };
	}
	undef @matches;
	
	foreach my $pos (@{$pSNP->{$ref}}) {
		#print "$pos\n";
		$total++;
		
		# Genes
		my $isGenic = 0;
		foreach my $i (0, -1, 1) {
			my $bin = int($pos/$ANNOT_BIN_SZ) + $i;
			foreach my $a (@{$pAnnot->{'gene'}{$ref}{$bin}}) {
				if (isOverlapping($pos, $a->{start}, $a->{end})) {
					$genic++;
					$isGenic = 1;
					goto NEXT1;
				}
			}
		}
		NEXT1:
		
		# Coding Sequences
		#if ($isGenic) {
			foreach my $i (0, -1, 1) {
				my $bin = int($pos/$ANNOT_BIN_SZ) + $i;
				foreach my $a (@{$pAnnot->{'cds'}{$ref}{$bin}}) {
					if (isOverlapping($pos, $a->{start}, $a->{end})) {
						$coding++;
						goto NEXT2;
					}
				}
			}
		#}
		NEXT2:

		# Junctions
		foreach my $i (0, -1, 1) {
			my $bin = int($pos/$READ_BIN_SZ) + $i;
			foreach my $j (@{$pJunc->{$ref}{$bin}}) {
				if (isOverlapping($pos, $j->{start}, $j->{end})) {
					$junc++;
					goto NEXT3;
				}
			}
		}
		NEXT3:
		
		# Reads
		my ($end5, $end3, $end1) = (0, 0, 0);
		my ($start5, $start3, $start1) = (0, 0, 0);
		my $within10 = 0;
		foreach my $i (0, -1, 1) {
			my $bin = int($pos/$READ_BIN_SZ) + $i;
			
			foreach my $r (@{$reads{$ref}{$bin}}) {
				my $start = $r->{start};
				my $end = $r->{end};
				
				if (isOverlapping($pos, $start, $start+9) or
					isOverlapping($pos, $end-9, $end)) 
				{
					$within10 = 1;
					goto NEXT4;
				}
				
#				if (isOverlapping($pos, $end-4, $end)) {
#					$end5 = 1;
#					if (isOverlapping($pos, $end-2, $end)) {
#						$end3 = 1;
#						if (isOverlapping($pos, $end, $end)) {
#							$end1 = 1;
#						}
#					}
#				}
#				if (isOverlapping($pos, $start, $start+4)) {
#					$start5 = 1;
#					if (isOverlapping($pos, $start, $start+2)) {
#						$start3 = 1;
#						if (isOverlapping($pos, $start, $start)) {
#							$start1 = 1;
#						}
#					}
#				}
			}
		}
		NEXT4:
		$notWithin10++ if (not $within10);
#		$endOfRead1++ if ($end1);
#		$endOfRead3++ if ($end3);
#		$endOfRead5++ if ($end5);
#		$startOfRead1++ if ($start1);
#		$startOfRead3++ if ($start3);
#		$startOfRead5++ if ($start5);
	}
}

print "\nTotal:         $total\n";
print "Genic:         $genic\n";
print "Coding:        $coding\n";
print "Junction:      $junc\n";
print "Not within 10 of read ends: $notWithin10\n";
#print "End of read:   (1)$endOfRead1 (3)$endOfRead3 (5)$endOfRead5\n";
#print "Start of read: (1)$startOfRead1 (3)$startOfRead3 (5)$startOfRead5\n";

exit;

#-------------------------------------------------------------------------------
sub loadSNP {
	my $filename = shift;
	my $pout;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my @tok;
	while (<INF>) {
		@tok = split /\t/;
		next if (@tok < 2);
		my $ref = $tok[0];
		my $pos = $tok[1];
		
		push @{ $pout->{$ref} }, $pos;
	}
	close(INF);
	
	return $pout;
}

sub loadJunctionBED {
	my $filename = shift;
	my $pout;
	
	my $count = 0;
	my $maxLen = 0;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $line;
	my @tok;
	while ($line = <INF>) {
		chomp $line;
		@tok = split /\t/,$line;
		next if (@tok < 12);
		
		my $ref     = $tok[0];
		my $start   = $tok[1];
		my $end     = $tok[2];
		my $bCount  = $tok[9];
		my @bSizes  = split(/,/, $tok[10]);
		my @bStarts = split(/,/, $tok[11]);
		
		# Check assumptions
		die "loadJunctionBED: end < start" if ($end < $start);
		die "loadJunctionBED: bCount > 2" if ($bCount > 2 or @bSizes > 2 or @bStarts > 2);
		
		# Determine just the start/end within a certain distance from the junction
		$end   = $start + $bStarts[1];
		$start = $start + $bSizes[0] + 1;
		my $DIST = 5;
		
		push @{ $pout->{$ref}{int($start/$READ_BIN_SZ)} }, { start => ($start - $DIST), end => $start };
		push @{ $pout->{$ref}{int($start/$READ_BIN_SZ)} }, { start => $end, end => ($end + $DIST) };
				
		$count++;
	}
	close(INF);
	
	print "loadJunctionBED: $count junctions\n";
	
	return $pout;
}

sub loadGFF {
	my $filename = shift;
	my $pTypes = shift;		# optional
	my $pout;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my %type_filter;
	%type_filter = map { lc($_) => 1 } @$pTypes if (defined $pTypes and @$pTypes > 0);
	
	my $count = 0;
	my $maxLen = 0;
	
	my $line;
	my @tok;
	while ($line = <INF>) {
		chomp $line;
		@tok = split /\t/,$line;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if (not defined $type_filter{$type});
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		push @{ $pout->{$type}{$ref}{int($start/$ANNOT_BIN_SZ)} }, 
				{ start => $start, end => $end };
				
		my $len = ($end - $start + 1);
		$maxLen = $len if ($len > $maxLen);
		$count++;
	}
	close(INF);
	
	print "loadGFF: $count annotations, max length $maxLen\n";

	return $pout;
}

sub isOverlapping {
	my $pos = shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return ($pos >= $s2 and $pos <= $e2);
}
