#!/usr/bin/perl
#
# Remove the specified section from the given FASTA file. 
#
# Author: Matt 11/06/14
#
# Program params --------------------------------------------------------------
my $inputF  = $ARGV[0]; # input file name 
my $secName = $ARGV[1]; # optional: section name 
# -----------------------------------------------------------------------------

use warnings;
use strict;

if (@ARGV < 2) {
    print "Usage:  fasta_remove.pl <input_filename> <section_name>\n";
    exit;
}

my $line;
my $outputOn = 0;

open my $inf,"<$inputF";
while ($line = <$inf>) {
    chomp $line;
    
    if ($line =~ /^\>(\S+)/) {
        $outputOn = 0;
        if ($1 ne $secName) { 
			$outputOn = 1;
		}
    }

    print "$line\n" if ($outputOn);
}
close $inf;
