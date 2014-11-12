#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	7/13/12
#------------------------------------------------------------------------------
my $DELIMITER1 = "\t";
my $DELIMITER2 = ",";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  tsv_to_csv.pl <filename>\n" if (@ARGV < 1);

while (my $line = <>) {
	$line =~ s/$DELIMITER1/$DELIMITER2/g;
	print $line;	
}

exit;

