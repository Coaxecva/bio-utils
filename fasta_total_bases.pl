#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/2/12
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_stats.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $total = 0;
my $totalACGT = 0;
my $totalN = 0;

my $parsex = qr/^\>\S+/;

open INF,"<$INPUT_FILE" or die "Can't open file: $INPUT_FILE\n";
while (my $line = <INF>) {
    chomp $line;
    
    if ($line !~ $parsex) { # Sequence data
        #$total += () = $line =~ /\S/g;
        #$totalN += () = $line =~ /N/g;
        $totalACGT += () = $line =~ /[ACGT]/g;
    }
}
close INF;

#print "Total characters: $total\n";
print "Total ACGT: $totalACGT\n";
#print "Total Ns: $totalN\n";

exit;

#-------------------------------------------------------------------------------
