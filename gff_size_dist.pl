#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	2/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my @ANNOT_TYPES = ('exon');
my @CHROMOSOMES = (1..19, 'X', 'Y','MT' );
#-------------------------------------------------------------------------------

use warnings;
use strict;

use lib "/home/mbomhoff/scripts";
use histogram;

die "Usage:  gff_size_dist.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $pSizes = loadGFFSizes($INPUT_FILE, \@ANNOT_TYPES, \@CHROMOSOMES);
print make_histogram($pSizes, undef, 24);

my ($avg, $var, $min, $max) = variance($pSizes);
my $med = $pSizes->[int((@$pSizes)/2)];
print "Avg: $avg\n";
print "Med: $med\n";
print "Var: $var\n";
print "Min: $min\n";
print "Max: $max\n";

exit;

#-------------------------------------------------------------------------------
sub variance {
	my $pArray = shift;
	my $num = scalar @$pArray;
	
	# Compute average
	my ($min, $max);
	my $total = 0;
	foreach my $x (@$pArray) {
		$total += $x;
		$min = min($min, $x);
		$max = max($max, $x);
	}
	my $avg = $total / $num;
	
	# Compute variance
	my $var = 0;
	foreach my $x (@$pArray) {
		my $diff = $x - $avg;
		$var += $diff * $diff / $num;
	}
	
	return ($avg, $var, $min, $max);
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

sub loadGFFSizes {
	my $filename = shift;
	my $pTypes = shift;			# optional
	my $pChromosomes = shift;	# optional
	my @out;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my %type_filter;
	%type_filter = map { lc($_) => 1 } @$pTypes if (defined $pTypes and @$pTypes > 0);
	my %ref_filter;
	%ref_filter = map {$_ => 1 } @$pChromosomes if (defined $pChromosomes and @$pChromosomes > 0);
	
	my $count = 0;
	my $line;
	my @tok;
	while (<INF>) {
		chomp;
		@tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		
		die "Error: invalid file format\n" if (@tok < 9);
		
		next if (defined $pTypes and not defined $type_filter{$type});
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding annotation due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		next if (defined $pChromosomes and not defined $ref_filter{$ref});
		
		push @out, $end-$start+1;
					
		$count++;
	}
	close(INF);
	
	print "$count annotations loaded\n";
	
	@out = sort {$a <=> $b} @out;

	return \@out;
}

