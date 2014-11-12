#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Merge two coverage FASTA files.
# Author:	mdb
# Created:	12/20/10
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  coverage_merge.pl <file1> <file2>\n" if ($#ARGV+1 < 2);

my $pCov1 = loadCoverageFastaFile($INPUT_FILE1);
my $pCov2 = loadCoverageFastaFile($INPUT_FILE2);

foreach my $ref (keys %$pCov1) { # assumes %cov2 has same keys
	print "$ref\n";
	foreach my $r (@{$pCov1->{$ref}}) {
		#print "   $r->{start}:$r->{end}\n";
		#my @a = sort { $a->{start} <=> $b->{start} } @{$pCov2->{$ref}};
		my $pOverlap = getInterval(\@{$pCov2->{$ref}}, $r->{start}, $r->{end});
		foreach my $r2 (@$pOverlap) {
			#print "      $r2->{start}:$r2->{end}\n";
		}
	}
}

exit;

#-------------------------------------------------------------------------------
sub getInterval {
	my $pList = shift;	# ref to array of non-overlapping regions sorted by start position
	my $start = shift;	# interval start
	my $end = shift;	# interval end
	my @out;
	
	# Binary search, assumes list of regions already sorted by start position
	my $i = int(scalar @$pList / 2);
	my $l = 0;
	my $r = scalar @$pList - 1;
	my $done = 0;
	while (not $done) {
		my $a = $pList->[$i];
		
		if ($end < $a->{start}) {
			$r = $i-1;
			$i -= int(($i-$l)/2);
		}
		elsif ($start > $a->{end}) {
			$l = $i+1;
			$i += int(($r-$i)/2);
		}
		else {
			$done = 1;
		}
		
		if ($done or ($r-$l) <= 1) {
			for (my $j = $l;  $j <= $r;  $j++) {
				$a = $pList->[$j];
				last if ($a->{start} > $end); # necessary?
				push @out, $a if getOverlap($start, $end, $a->{start}, $a->{end});
			}
			$done = 1;
		}
	}
	
	return \@out;
}

sub isOverlapping {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return ($s1 <= $e2 and $s2 <= $e1);
}

sub getOverlap {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return 0 if (not isOverlapping($s1, $e1, $s2, $e2));
	
	my $s = max($s1, $s2);
	my $e = min($e1, $e2);
	
	return ($e - $s + 1);
}

sub joinRegions { # join array of regions and maintain gaps in-between
	my $pRegions = shift;#sort {$a->{start} <=> $b->{start}} @_;
	my %out;
	
	for (my $i = 0;  $i < @$pRegions;  $i++) {
		my $r1 = $pRegions->[$i];
		my $r2 = $pRegions->[$i+1];
		
		$out{seq} .= $r1->{seq};
		my $gap = 0;
		if (defined $r2) {
			$gap = $r2->{start} - $r1->{end} - 1;
			if ($gap > 0) {
				$out{seq} .= 'N' x $gap;
			}
			elsif ($gap < 0) { # overlapping
				$out{seq} = substr($out{seq}, 0, $gap);
			}
		}
		
		$out{start} = $r1->{start} if (not defined $out{start});
		$out{end}   = $r1->{end}   if (not defined $out{end});
		$out{start} = min($out{start}, $r1->{start});
		$out{end}   = max($out{end},   $r1->{end});
	}
	
	return \%out;
}

sub loadCoverageFastaFile {
	my $filename = shift;
	my %out;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $line;
	my $lineNum = 0;
	my ($ref, $start, $end, $seq);
	my @tok;
	while ($line = <INF>) {
		$lineNum++;
		chomp $line;
		
		if ($line =~ /^\>(.*)/) {
			@tok = split(/\,/, $1);
			
			if (defined $seq and length $seq > 0 and $ref !~ /^NT\_/) {
				die "Error: sequence length mismatch for $filename:$ref:$start:$end $seq\n"
					if ($end-$start+1 != length $seq);
				push @{$out{$ref}}, { start => $start, end => $end, seq => $seq };
			}
			
			$ref   = $tok[0];
			$start = $tok[1];
			$end   = $tok[2];
			$seq = '';
			
			die "Error: fields missing in coverage file, line $lineNum\n" if (scalar @tok < 3);
			die "Error: invalid coordinates $start:$end, line $lineNum\n" if ($end < $start);
		}
		else {
			$seq .= $line;
		}
	}
	close(INF);
	
	# Last record
	if (defined $seq and length $seq > 0 and $ref !~ /^NT\_/) {
		die "Error: sequence length mismatch for $filename:$ref:$start:$end $seq\n"
			if ($end-$start+1 != length $seq);
		push @{$out{$ref}}, { start => $start, end => $end, seq => $seq };
	}
	
	return \%out;
}

sub min {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x <= $y);
	return $y;
}

sub max {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x >= $y);
	return $y;
}
