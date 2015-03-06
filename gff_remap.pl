#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:  Remap GFF reference names using an NCBI assembly report and print
#           to STDOUT.
# Author:   Matt Bomhoff (matthew.bomhoff@gmail.com)
# Created:  5/6/15
#------------------------------------------------------------------------------
my $INPUT_GFF_FILE = $ARGV[0]; # gff file to remap
my $INPUT_ASM_FILE = $ARGV[1]; # assembly report txt file
die "Usage: perl gff_remap.pl <gff_file> <asm_file>\n" unless ($INPUT_GFF_FILE and $INPUT_ASM_FILE);
#-------------------------------------------------------------------------------

use warnings;
use strict;

# Load reference names from assembly report file
my %names;
open(my $fh,"<$INPUT_ASM_FILE") or die "Can't open file: $INPUT_ASM_FILE\n";
while (<$fh>) {
    next if (/^#/);
    chomp;
    my @tok = split("\t");
    my $name1 = $tok[4]; 
    my $name2 = $tok[6];
    
    # Skip "na" ("not applicable"), there's nothing to map to
    next if (lc($name1) eq 'na');
    
    $names{$name2} = $name1 if (defined $name1 and defined $name2);
}
close($fh);

# Remap gff reference names
open($fh,"<$INPUT_GFF_FILE") or die "Can't open file: $INPUT_GFF_FILE\n";
while (<$fh>) {
    next if (/^#/);
    chomp;
    my @tok = split("\t");
    
    # Skip chromosome features
    my $type = $tok[2];
    next if (lc($type) eq 'region');
    
    # Print line with new reference name
    my $name = $tok[0];
    unless (defined $names{$name}) {
        #print STDERR "# Name not found $name\n";
        next;
    }
    $tok[0] = $names{$name} if (defined $names{$name});
    print join("\t", @tok), "\n";
}
close($fh);

exit;
