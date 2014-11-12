#!/usr/bin/env perl
#
# Convert a phylip file to FASTA format.  
#
# mdb 3/29/11
# ------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  phylip_to_fasta.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $INF = shift @ARGV;  	# input file name 
my ($OUTF) = $INF =~ /^(.*)\.phylip/;
$OUTF .= '.fasta';

open my $inf,"<$INF" or die "Can't open file: $INF\n";

open my $outf,">$OUTF" or die "Can't open file: $OUTF\n";

while (<$inf>) {
    chomp;
    
    if (/^(\w+)\s+(\w+)/) {
        my $secName = $1;
        my $seq = $2;
        print_fasta($outf, $secName, \$seq);
    }
}
close $inf;
close $outf;

exit;

#-------------------------------------------------------------------------------
sub print_fasta {
	my $fh = shift;
	my $name = shift;	# fasta section name
	my $pIn = shift; 	# reference to section data
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
	print {$fh} ">$name\n";
    while ($ofs < $len) {
    	print {$fh} substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
}