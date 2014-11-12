#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Take a phylip file that has read depths after the sequence
#           and calculate the mean read depth.
# Author:	mdb
# Created:	5/25/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];  # input filename
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  phylip_mean_depth.pl <input_filename>\n" if ($#ARGV+1 < 1);

open(my $fh, "<$INPUT_FILE") or die "Can't open file: $INPUT_FILE\n";

my $name;
my $seq;
my $depths;
while (my $line = <$fh>) {
	chomp $line;
    if ($line =~ /^(.*)\t(.*)\t(.*)/) {
		$name = $1;
		$seq = $2;
		$depths = $3;
		last;
    }
}
close($fh);

die if (not defined $seq);
die if (not defined $depths);

my $s;
my $sum = 0;
my @a = unpack("C*", $depths);
for (my $i = 0;  $i < @a;  $i++) {
	my $depth = $a[$i]-32;
	$sum += $depth;
	#print "$depth\n";
}

print "Mean: " . sprintf("%.1f", $sum / @a) . "\n";

exit;

#-------------------------------------------------------------------------------
