#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count number of columns in file.
# Author:	mdb
# Created:	7/6/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  count_col.pl <input_filename>\n" if (@ARGV < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $i = 1;
my $count = 0;
while (<INF>) {
	chomp;
	my @tok = split /$DELIMITER/;
	$count = @tok;
	print "$i: $count\n";
	#last;
	$i++;
}
close(INF);

#print "$count columns\n";

exit;

