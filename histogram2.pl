#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Generates a histogram.
# Author:	mdb
# Created:	4/13/12
#------------------------------------------------------------------------------
my $inputF = $ARGV[0];      # input filename, whitespace delimited
my $col = $ARGV[1];         # column number, starting at 0
my $numBuckets = $ARGV[2];
my $increment;
   $increment = 0.1 if (not defined $numBuckets);
my $skipLines = 0;       	# number of lines to skip at top of file
# -----------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

if ($#ARGV+1 < 2) {
    print "Usage:  histogram <input_filename> <column_number> [num_buckets]\n";
    exit;
}

$| = 1; # enable autoflush

my $count = 0;
my %hashCount;

#open inputF,"<$inputF" or die "Can't open file: $inputF\n";
#while (<inputF>) {
#    next if ($count++ < $skipLines); # skip file header
#    chomp;
#    next if (/^#/); # skip comment lines
#    my @tok = split(/\s+/);
#    my $val = $tok[$col];
#    next if (not defined $val or $val !~ /[\.\d]/);
#    $hashCount{$val}++;
#}
#close inputF;

open inputF,"<$inputF" or die "Can't open file: $inputF\n";
while (<inputF>) {
    next if ($count++ < $skipLines); # skip file header
    chomp;
    next if (/^#/); # skip comment lines
    my @tok = split(/\s+/);
    my $val = $tok[$col];
    next if (not defined $val or $val !~ /[\.\d]/);
	if ($val > 0 and $val < 1) { $val = 1; }
    $val = int($val);
    $hashCount{$val}++;
    #print "\r$count          " if (($count % 1000000) == 0);
}
close inputF;
print "\n";

print make_histogram2(\%hashCount, undef, 1);

exit;