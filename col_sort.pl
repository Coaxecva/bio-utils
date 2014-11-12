#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:  Sort lines in file based on values in specified column.
# Author:	mdb
# Created:	6/12/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
my $DELIMITER = "\t";
my $SKIP_FIRST_LINE = 1;	# option to skip header line
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  count_sort.pl <input_filename> <column_num>\n" if (@ARGV < 2);

my %lines;

open(my $fh, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
<$fh> if ($SKIP_FIRST_LINE);
while (my $line = <$fh>) {
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	next if (@tok < $COL); #die "Error: column $COL doesn't exist in file! " . @tok . "\n" if (@tok < $COL);
	
	my $val = $tok[$COL];
	next if ($val =~ /[a-zA-Z]/);
	if ($val =~ /-{0,1}\d*\.{0,1}\d+/) {
		$lines{$val} = $line;
	}
}
close($fh);

foreach my $val (sort {$b <=> $a} keys %lines) {
	print "$lines{$val}\n";
}

exit;

