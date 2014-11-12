#!/usr/bin/perl
#
# Extract the specified section from the given FASTA file (or all sections
# if not specified). 
#
# Author: Matt 5/31/07
#
# Program params --------------------------------------------------------------
my $inputF  = $ARGV[0]; # input file name 
my $secName = $ARGV[1]; # optional: section name 
# -----------------------------------------------------------------------------

use warnings;
use strict;

if ($#ARGV+1 < 1) {
    print "Usage:  fasta_section.pl <input_filename> [section_name]\n";
    exit;
}

my $line;
my $outputOn = 0;
my $useName = (defined $secName and $secName ne "");

open inputF,"<$inputF";
while ($line = <inputF>) {
    chomp $line;
    
    if ($line =~ /^\>(\S+)/) {
		$secName = $1 if (not $useName);
        if ($1 eq $secName) { 
			$outputOn = 1;
			close outputF;
			open outputF,">$secName.fasta";
		}
        elsif ($outputOn) { 
			last;
		}
    }

    print outputF "$line\n" if ($outputOn);
}
close outputF;
close inputF;
