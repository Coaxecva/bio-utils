#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count reads in .BAM file that overlap junctions.
# Author:	mdb
# Created:	2/16/11
#------------------------------------------------------------------------------
my $BAM_INPUT_FILE = $ARGV[0];
#------------------------------------------------------------------------------
my @CHROMOSOMES = ( 1..19, 'X', 'Y','MT' );
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

$| = 1;

die "Usage:  bam_stats4.pl <bam file>\n" if ($#ARGV+1 < 1);

my %juncs;
loadJunc(\%juncs, '/data/genome/mus/known.junc');

my $sam = Bio::DB::Sam->new(-bam => $BAM_INPUT_FILE);

#my @refs = $sam->seq_ids;

my %counted;
foreach my $ref (@CHROMOSOMES) {
	print "$ref\n";
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	
	my $prev;
	foreach my $r (sort {$a->start <=> $b->start} @matches) {
		my $name = $r->query->name;
		next if (defined $counted{$name});
		
		my $start = $r->start;
		my $end = $r->end;
		my $len = $end - $start + 1;
		die "end < start" if ($end < $start); # check assumption
					
		# Check previous annotation
		if (defined $prev and isOverlapping($start, $end, $prev->{start}, $prev->{end})) {
			$counted{$name} = 1;
			goto NEXT;
		}
			
		# Search all junctions
#		my $b = int($start/$BIN_SZ{$type});
#		foreach my $i (0, -1, 1) {
			foreach my $j (@{$juncs{$ref}}) { #{$b+$i}}) {
				if (isOverlapping($start, $end, $j->{start}, $j->{end})) {
					$counted{$name} = 1;
					$prev = $j;
					goto NEXT;
				}
			}
#		}
		NEXT:
	}
}

#print "Max read map dist: $maxGap\n";
print "Overlapping: " . (keys %counted) . "\n";	

exit;

#-------------------------------------------------------------------------------
sub loadJunc {
	my $pout = shift;
	my $filename = shift;
	
	my $count = 0;
	my $maxLen = 0;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while (<INF>) {
		chomp;
		my @tok = split /\t/;
		die if (@tok < 4);
		
		my $ref     = $tok[0];
		my $start   = $tok[1];
		my $end     = $tok[2];
		my $strand  = $tok[3];
		
		next if (not grep {$_ eq $ref} @CHROMOSOMES);
		
		# Check assumptions
		die "loadJunc: end < start" if ($end < $start); 
		
		# Get coordinates of read overlap on edges of junction, but not in-between
		push @{ $pout->{$ref} }, { start => $start, end => $end, strand => $strand };
				
		my $len = $end - $start + 1;
		$maxLen = $len if ($len > $maxLen);
		
		$count++;
	}
	close(INF);
	
	print "loadJunc: $count junctions, max length $maxLen\n";
	
	return $pout;
}

sub isOverlapping {
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return ($s1 <= $e2 and $s2 <= $e1);
}
