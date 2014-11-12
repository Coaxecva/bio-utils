#!/usr/bin/env perl
#
# Convert all phylip files in current directory to FASTA format, name sections
# based on filename.
#
# mdb 9/19/11
# ------------------------------------------------------------------------------

use warnings;
use strict;

foreach my $file (<*.phylip>) {
	my ($name) = $file =~ /(\S+)\.phylip/;
	
	open my $fh,"<$file" or die "Can't open file: $file\n";
	while (<$fh>) {
	    chomp;
	    
	    if (/^\w+\s+(\w+)/) {
	        print_fasta($name, \$1);
	    }
	}
	close $fh;
}

exit;

#-------------------------------------------------------------------------------
sub print_fasta {
	my $name = shift;	# fasta section name
	my $pIn = shift; 	# reference to section data
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
	print ">$name\n";
    while ($ofs < $len) {
    	print substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
}