#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Script for Megan to join fields in tsv files on ID.
# Author:	mdb
# Created:	1/31/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = 'gnf1m.annot2007 2.tsv';
my $INPUT_FILE2 = 'GNF1M_plus_macrophage_small.bioGPS.txt';
#-------------------------------------------------------------------------------

use warnings;
use strict;

my $line;
my @tok;

my %records;

open(INF, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while ($line = <INF>) {
	chomp $line;
	@tok = split /\t/,$line;
	my $id = $tok[0];
	$records{$id} = { mmref => $tok[3], sym => $tok[6] };
}
close(INF);

open(INF, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while ($line = <INF>) {
	chomp $line;
	@tok = split /\t/,$line;
	my $id = $tok[0];
	my $testis1 = $tok[40];
	my $testis2 = $tok[41];
	
	if (defined $records{$id}) {
		print "$records{$id}{mmref}\t$records{$id}{sym}\t$testis1\t$testis2\n";
	}
}
close(INF);

exit;

#-------------------------------------------------------------------------------
