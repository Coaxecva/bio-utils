#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Generates a histogram.
# Author:	mdb
# Created:	4/27/07
#------------------------------------------------------------------------------
my $inputF = $ARGV[0];      # input filename, whitespace delimited
my $col = $ARGV[1];         # column number, starting at 0
my $numBuckets = $ARGV[2];
my $increment;
   $increment = 0.1 if (not defined $numBuckets);
my $skipLines = 0;       	# number of lines to skip at top of file
my $SIG_FIGS = 4; 			# default for displaying real nums
# -----------------------------------------------------------------------------

use warnings;
use strict;
use POSIX;

if ($#ARGV+1 < 2) {
    print "Usage:  histogram <input_filename> <column_number> [num_buckets]\n";
    exit;
}

# Get column values
my $sigFigs = 0;
my $count = 0; 
my @vals;
open inputF,"<$inputF" or die "Can't open file: $inputF\n";
while (<inputF>) {
    next if ($count++ < $skipLines); # skip file header
    chomp;
    next if (/^#/); # skip comment lines
    my @tok = split(/\s+/);
    my $val = $tok[$col];
    next if (not defined $val or $val !~ /[\.\d]/);
    push @vals, $val;
    $sigFigs = $SIG_FIGS if ($val != int($val));
}
close inputF;

my ($avg, $med, $var, $min, $max) = stats(\@vals);

my $width;
my @buckets;
if (defined $increment) {
	$width = $increment;
}
else {
	$numBuckets = 1 if (not defined $numBuckets);
	$width = (($max - $min) / $numBuckets);
}
#$width = (($max - $min) / $numBuckets);
print "avg=" . sprintf("%.4f", $avg) . " med=" . sprintf("%.4f", $med) . " var=" . sprintf("%.4f", $var) . " min=" . sprintf("%.4f", $min) . " max=" . sprintf("%.4f", $max) . "\n";

# Fill buckets
foreach (@vals) {
    $buckets[int(($_-$min)/$width)]++; # note: can cause empty buckets
}
@vals = ();

# Find min and max counts
my ($minCount,$maxCount);
my $totalCount = 0;
foreach my $x (@buckets) {
	next if (not defined $x);
    $minCount = $x if (not defined $minCount or $x < $minCount);
    $maxCount = $x if (not defined $maxCount or $x > $maxCount);
    $totalCount += $x;
}
print "minCount=$minCount maxCount=$maxCount totalCount=$totalCount buckets=" . (defined $numBuckets ? $numBuckets : '') . " width=$width\n\n";

# Display histogram
$count = 0;
my $scale = 60/($maxCount-$minCount+1);
my $runCount = 0;
my $skipped = '';
print "Value\tCount\tPercents\n";
foreach my $x (@buckets) {
    if (defined $x) {
        printf "$skipped%." . $sigFigs . "f\t$x\t" . int(100*$x/$totalCount) . ":" . int(100*$runCount/$totalCount) . "\t" . "*" x (($x * $scale)+1) . "\n", $count+$min;   
        $skipped = '';
        $runCount += $x;
    }
    else { # Empty bucket
        print ".";
        $skipped = "\n";
    }
    $count += $width;
}
print "\n";

#-------------------------------------------------------------------------------
sub stats {
	my $pArray = shift; # reference to array of scalars
	my $num = scalar @$pArray;
	
	# Compute average
	my ($min, $max);
	my $total = 0;
	foreach my $x (@$pArray) {
		$total += $x;
		$min = $x if (not defined $min or $x < $min);
		$max = $x if (not defined $max or $x > $max);
	}
	my $avg = $total / $num;
	
	# Compute variance
	my $var = 0;
	foreach my $x (@$pArray) {
		my $diff = $x - $avg;
		$var += $diff * $diff / $num;
	}
	
	# Compute median
	my @a = sort {$a<=>$b} @$pArray;
	my $middle = (@a+1)/2 - 1;
	my $a1 = $a[floor($middle)];
	my $a2 = $a[ceil($middle)];
	my $med = ($a1+$a2)/2;
	
	return ($avg, $med, $var, $min, $max);
}

