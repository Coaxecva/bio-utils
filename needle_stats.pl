#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/31/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "usage:  perl needle_to_fasta.pl <filename>\n" if (@ARGV < 1);

my %seq;
my $name;

open INF, $INPUT_FILE or die "Cannot open input file '$INPUT_FILE'\n";
while (<INF>) {
	chomp;
	next if (/^#/);
	
	if (/^(\S+)\s+(\d+)\s+(\S+)\s+(\d+)/) {
		#$seq{$1} .= $3;
		if (not defined $name or $name eq 'bottom') {
			$name = 'top';	
		}
		else {
			$name = 'bottom';
		}
		$seq{$name} .= $3;
	}
}
close INF;

my ($acgt1, $acgt2, $segment, $match, $mismatch, $n, $gap, $pMatches, $pMismatches, $pSegments) = diffSequences(values %seq);
my @names = keys %seq;

print "Names:      $names[0] ($acgt1), $names[1] ($acgt2)\n";
print "Ns:         $n\n";
print "Gaps:       $gap\n";
print "Segments (N's, matches, mismatches):   $segment\n";
foreach my $r (@$pSegments) {
	print "   $r->{start}:$r->{end} " . ($r->{end}-$r->{start}+1) . "\n";	
}
print "Matches:    $match\n";
foreach my $r (@$pMatches) {
	print "   $r->{start}:$r->{end} " . ($r->{end}-$r->{start}+1) . "\n";	
}
print "Mismatches: $mismatch\n";
foreach my $m (@$pMismatches) {
	print "   $m->{pos}: $m->{base1},$m->{base2}\n";	
}

exit;

#-------------------------------------------------------------------------------
sub diffSequences { # make this faster using string bitwise ops
	my $s1 = shift;
	my $s2 = shift;
	
	my @a1 = split(//, $s1);
	my @a2 = split(//, $s2);
	die "diffSequences: not same length " . @a1 . " " . @a2 if (@a1 != @a2);
	
	my ($acgt1, $acgt2) = (0, 0);
	my ($segment, $mismatch, $match, $n, $gap) = (0, 0, 0, 0, 0);
	my @matches;
	my @mismatches;
	my @segments;
	my $matchStart;
	my $segStart;
	
	for (my $i = 0;  $i < @a1;  $i++) {
		my $isMatch = 0;
		my $isGap = 0;
		my $c1 = $a1[$i];
		my $c2 = $a2[$i];
		
		$acgt1++ if ($c1 =~ /[ACGTBDHKMRSWVXY]/);
		$acgt2++ if ($c2 =~ /[ACGTBDHKMRSWVXY]/);
		
		if ($c1 eq '-' or $c2 eq '-') {
			$gap++;
			$isGap = 1;
		}
		elsif ($c1 eq 'N' or $c2 eq 'N') {
			$n++;
		}
		elsif ($c1 eq $c2) {
			$match++;
			$isMatch = 1;
			$matchStart = $i if (not defined $matchStart);
		}
		else {
			$mismatch++;
			push @mismatches, { pos => $i, base1 => $c1, base2 => $c2 };
		}
		
		if (defined $matchStart and not $isMatch) {
			push @matches, { start => $matchStart, end => $i-1 };
			undef $matchStart;
		}
		
		if (not defined $segStart and not $isGap) {
			$segStart = $i;
		}
		elsif (defined $segStart and $isGap) {
			push @segments, { start => $segStart, end => $i-1 };
			$segment += $i-1 - $segStart + 1;
			undef $segStart;
		}
	}
	
	return ($acgt1, $acgt2, $segment, $match, $mismatch, $n, $gap, \@matches, \@mismatches, \@segments);
}