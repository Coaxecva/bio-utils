#!/usr/bin/env perl
#
# Convert a FASTA file to phylip format.  
#
# mdb 5/18/11
# ------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_to_phylip.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $INF = shift @ARGV;  	# input file name 

my $name;
my $seq;

open INF,"<$INF" or die "Can't open file: $INF\n";
while (my $line = <INF>) {
    chomp $line;
    if ($line =~ /^>\s*(\S+)/) {
    	finish() if (defined $name);
        $name = $1;
        $seq = '';
    }
    else {
    	my ($s) = $line =~ /\S+/g; # because of Windows end-of-line	
    	$seq .= $s;
    }
}
close INF;
finish();

exit;

#-------------------------------------------------------------------------------
sub finish {
	print "$name\t$seq\n";	
}