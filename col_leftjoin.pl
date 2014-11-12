#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Left-join two tables in separate files on specified column.
# Author:	mdb
# Created:	5/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
my $COL = $ARGV[2];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_leftjoin.pl <file1> <file2> <col>\n" if (@ARGV < 3);

my %lines;
open(my $f1, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while (my $line = <$f1>) {
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	$lines{$val} = $line;
}
close($f1);

open(my $f2, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while (my $line = <$f2>) {
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	splice @tok, $COL, 1;
	$lines{$val} .= $DELIMITER . join($DELIMITER, @tok);
}
close($f2);

foreach my $val (sort keys %lines) {
	print "$lines{$val}\n";	
}

exit;

