#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Join two tables in separate files on specified column.
# Author:	mdb
# Created:	5/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
my $COL = $ARGV[2]; # optional, default is 0
   $COL = 0 if (not defined $COL);
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_merge.pl <file1> <file2> <col>\n" if (@ARGV < 2);

my %lines;
my %lines1;
my $numFields1 = 0;
open(my $f1, $INPUT_FILE1) or 
	die("Error: cannot open file '$INPUT_FILE1'\n");
while (my $line = <$f1>) {
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	splice @tok, $COL, 1;
	$lines1{$val} = join($DELIMITER, @tok);
	$lines{$val}++;
	$numFields1 = @tok;
}
close($f1);

my %lines2;
my $numFields2 = 0;
open(my $f2, $INPUT_FILE2) or 
	die("Error: cannot open file '$INPUT_FILE2'\n");
while (my $line = <$f2>) {
	chomp $line;
	my @tok = split(/$DELIMITER/, $line);
	my $val = $tok[$COL];
	next if (not defined $val);
	$val =~ s/\"//g; # remove quotes
	splice @tok, $COL, 1;
	$lines2{$val} = join($DELIMITER, @tok);
	$lines{$val}++;
	$numFields2 = @tok;
}
close($f2);

#foreach my $val (sort keys %lines) {
#	print "$val$DELIMITER";
#	if (defined $lines1{$val}) {
#		print $lines1{$val};	
#	}
#	else {
#		print $DELIMITER x ($numFields1-1);	
#	}
#	print $DELIMITER;
#	if (defined $lines2{$val}) {
#		print "$lines2{$val}";	
#	}
#	else {
#		print $DELIMITER x ($numFields2-1);	
#	}
#	print "\n";
#}
foreach my $val (sort keys %lines1) {
	next if (not defined $lines2{$val});
	print "$val$DELIMITER$lines1{$val}$DELIMITER$lines2{$val}\n";
}

exit;

