#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Join two tables in separate files on col1 and col2, display 
#           rows in second file only.
# Author:	mdb
# Created:	5/4/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
my $COL1 = $ARGV[2];
my $COL2 = $ARGV[3];
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_pivot.pl <file1> <file2> <col1> <col2>\n" if (@ARGV < 4);

my %unique;

open(INF1, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while (<INF1>) {
	chomp;
	my @tok = split /\t/;
	my $val = $tok[$COL1];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	$unique{$val}++;
}
close(INF1);

open(INF2, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while (my $line = <INF2>) {
	chomp $line;
	my @tok = split(/\t/, $line);
	my $val = $tok[$COL2];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	print "$line\n" if (defined $unique{$val});
}
close(INF2);

exit;

