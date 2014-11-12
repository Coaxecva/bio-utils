#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/26/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0]; # input pileup filename 1 
my $INPUT_FILE2 = $ARGV[0]; # input pileup filename 2
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_line_info.pl <pileup1> <pileup2>\n" if ($#ARGV+1 < 2);

open(my $inf1, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
	
open(my $inf2, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");

my $parsex = qr/^(\S+)\t(\S+)\t\S+\t(\S+)/; # mpileup format

while (not eof($inf1) and not eof($inf2)) {
	my $line1 = <$inf1>;
	my $line2 = <$inf2>;
	
	my ($ref1, $pos1, $depth1) = $line1 =~ $parsex; 
	my ($ref2, $pos2, $depth2) = $line2 =~ $parsex; 
	
	if ($ref1 ne $ref2 or 
		$pos1 ne $pos2 or
		$depth1 ne $depth2)
	{
		print "$ref1,$pos1,$depth1\t$ref2,$pos2,$depth2\n";		
	}
}
close($inf1);
close($inf2);

exit;

#-------------------------------------------------------------------------------
