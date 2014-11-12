#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Prints stats on mapping
# Author:	mdb
# Created:	1/19/11
#------------------------------------------------------------------------------
my $BAM_INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

use lib "/home/mbomhoff/scripts";
use histogram;

die "Usage:  bam_get_reads.pl <bam file>\n" if ($#ARGV+1 < 1);

#
# Get mapped read IDs from BAM file
#

my $sam = Bio::DB::Sam->new(-bam => $BAM_INPUT_FILE);

my @refs = $sam->seq_ids;
my %reads;
my $totalHits = 0;
my ($maxGap, $minGap) = (0, 9999999);
my $minMatches = 999999;
my $maxMismatches = 0;
my ($pMaxGapRead, $pMinGapRead, $pMinMatchesRead);

foreach my $ref (@refs) {
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	
	foreach my $r (@matches) {
		my $name =  $r->query->name;
		my $start = $r->start;
		my $end = $r->end;
		die "end < start" if ($end < $start);
		my $len = $end-$start+1;
		if ($len > $maxGap) {
			$maxGap = $len;
			$pMaxGapRead = { ref => $ref, name => $name, start => $start, end => $end };	
		}
		elsif ($len < $minGap) {
			$minGap = $len;
			$pMinGapRead = { ref => $ref, name => $name, start => $start, end => $end };	
		}
		
		my $cigar = $r->cigar_str;
		foreach my $matches ($cigar =~ /(\d+)M/g) {
			if (defined $matches and $matches < $minMatches) {
				$minMatches = $matches;
				$pMinMatchesRead = { ref => $ref, name => $name, start => $start, end => $end };
			}
		}
		foreach my $matches ($cigar =~ /(\d+)\=/g) {
			if (defined $matches and $matches < $maxMismatches) {
				$maxMismatches = $matches;
				#$pMinMatchesRead = { ref => $ref, name => $name, start => $start, end => $end };
			}
		}
		
		$reads{$name}{$ref}++;
		$totalHits++;
	}
}
undef $sam;

#
# Count types of hits
#

my $singleHits = 0;
my $multiHits = 0;
my $chrHits = 0;
foreach my $name (keys %reads) {
	my $hits = 0;
	$hits += $_ foreach (values %{$reads{$name}});
	
	if ($hits == 1) {
		$singleHits++;
	}
	else {
		#print "$name\t$hits\n" if ($hits >= 100);
		$multiHits++;
		$chrHits++ if (keys %{$reads{$name}} > 1);
	}
}

print "BAM total hits:    $totalHits\n";
print "unique reads:      " . (keys %reads) . "\n";
print "single-hit reads:  $singleHits\n";
print "multi-hit reads:   $multiHits\n";
print "multi-chr reads:   $chrHits\n";
print "max mapping dist:  $maxGap, $pMaxGapRead->{name} $pMaxGapRead->{ref}:$pMaxGapRead->{start}:$pMaxGapRead->{end}\n";
print "min mapping dist:  $minGap, $pMinGapRead->{name} $pMinGapRead->{ref}:$pMinGapRead->{start}:$pMinGapRead->{end}\n";
print "min matches:       $minMatches, $pMinMatchesRead->{name} $pMinMatchesRead->{ref}:$pMinMatchesRead->{start}:$pMinMatchesRead->{end}\n";
print "max mismatches:    $maxMismatches\n";#, $pMinMatchesRead->{name} $pMinMatchesRead->{ref}:$pMinMatchesRead->{start}:$pMinMatchesRead->{end}\n";

#print make_histogram([values %reads], undef, 1); 

exit;

#-------------------------------------------------------------------------------

