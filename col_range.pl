#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print range of values in specified column.
# Author:	mdb
# Created:	4/12/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  count_range.pl <input_filename> <column_num>\n" if (@ARGV < 2);

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $count = 0;
my ($min,$max);
while (<$fh>) {
	chomp;
	my @tok = split /$DELIMITER/;
	next if (@tok < $COL); #die "Error: column $COL doesn't exist in file! " . @tok . "\n" if (@tok < $COL);
	
	my $val = $tok[$COL];
	next if ($val =~ /[a-zA-Z]/);
	if ($val =~ /-{0,1}\d*\.{0,1}\d+/) {
		$min = $val if (not defined $min or $val < $min);
		$max = $val if (not defined $max or $val > $max);
		$count++;
	}
}
close($fh);

print "Count: $count\n" .
	  "Min:   $min\n" .
	  "Max:   $max\n";

exit;

