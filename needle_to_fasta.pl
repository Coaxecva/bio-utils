#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/30/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "usage:  perl needle_to_fasta.pl <filename>\n" if (@ARGV < 1);

my %seq;

open INF, $INPUT_FILE or die "Cannot open input file '$INPUT_FILE'\n";
while (<INF>) {
	chomp;
	next if (/^#/);
	
	if (/^(\w+)\s+(\d+)\s+(\S+)\s+\d+/) {
		#print "$1 $2 $3\n";
		$seq{$1} .= $3;
	}
}
close INF;

foreach my $name (sort keys %seq) {
	print_fasta($name, \$seq{$name});
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
