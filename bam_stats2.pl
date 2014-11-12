#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count reads in .BAM file that overlap annotations.
# Author:	mdb
# Created:	1/20/11
#------------------------------------------------------------------------------
my $BAM_INPUT_FILE = $ARGV[0];
my %BIN_SZ = ( 	gene => 2000000, 
				cds  => 500000 );
# Note on binning:  bin size needs to be at least 1/3 of the largest annotation
# and the largest read mapping distance.
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

$| = 1;

die "Usage:  bam_stats2.pl <bam file>\n" if ($#ARGV+1 < 1);

my @annot_types;
push @annot_types, 'gene';
push @annot_types, 'cds';
my %annot;
loadGFF(\%annot, '/data/genome/mus/old/combined.gtf', \@annot_types);
push @annot_types, 'junc';
loadJunctionBED(\%annot, '/data/transcriptome/tophat/tophat_DJO/junctions.bed');

my $sam = Bio::DB::Sam->new(-bam => $BAM_INPUT_FILE);

my @refs = $sam->seq_ids;
my %overlappingByType;

my $maxGap = 0;
foreach my $ref (@refs) {
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	
	my %prev;
	foreach my $type (@annot_types) {
		my %overlapping;
		foreach my $r (sort {$a->start <=> $b->start} @matches) {
			my $name = $r->query->name;
			next if (defined $overlapping{$name});
			
			my $start = $r->start;
			my $end = $r->end;
			my $len = $end - $start + 1;
			$maxGap = $len if ($len > $maxGap);
			die "end < start" if ($end < $start); # check assumption
			
			# Check previous annotation
			if (defined $prev{$type} and isOverlapping($start, $end, $prev{$type}->{start}, $prev{$type}->{end})) {
				$overlapping{$name} = 1;
				goto NEXT;
			}
			
			# Search all annotations
			my $b = int($start/$BIN_SZ{$type});
			foreach my $i (0, -1, 1) {
				foreach my $a (@{$annot{$type}{$ref}{$b+$i}}) {
					if (isOverlapping($start, $end, $a->{start}, $a->{end})) {
						$overlapping{$name} = 1;
						$prev{$type} = $a;
						goto NEXT;
					}
				}
			}
			NEXT:
		}
		my $num = scalar keys %overlapping;
		print "$type:$ref:$num ";
		$overlappingByType{$type} += $num;
	}
}
print "\n";

print "Max read map dist: $maxGap\n";
foreach my $type (keys %overlappingByType) {
	print "Total reads overlapping '$type': $overlappingByType{$type}\n";	
}

exit;

#-------------------------------------------------------------------------------
sub loadJunctionBED {
	my $pout = shift;
	my $filename = shift;
	
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
		
		# Get coordinates of read overlap on edges of junction, but not in-between
		push @{ $pout->{junc}{$ref}{int($start/$BIN_SZ{junc})} }, 
				{ start => $start, end => $start + $bSizes[0] };
		$maxLen = $bSizes[0] if ($bSizes[0] > $maxLen);
		
		$start = $start + $bStarts[1];
		push @{ $pout->{junc}{$ref}{int($start/$BIN_SZ{junc})} }, 
				{ start => $start, end => $end };
		$maxLen = $bSizes[1] if ($bSizes[1] > $maxLen);
				
		$count++;
	}
	close(INF);
	
	print "loadJunctionBED: $count junctions, max length $maxLen\n";
	
	return $pout;
}

sub loadGFF {
	my $pout = shift;
	my $filename = shift;
	my $pTypes = shift;		# optional

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
		
		push @{ $pout->{$type}{$ref}{int($start/$BIN_SZ{$type})} }, 
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
	my $s1 	= shift;
	my $e1 	= shift;
	my $s2 	= shift;
	my $e2 	= shift;
	
	return ($s1 <= $e2 and $s2 <= $e1);
}
