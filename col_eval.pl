#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	1/25/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $COL = $ARGV[1]; 		# column number, starting at 0
my $EXPR = $ARGV[2]; 		# perl expression to eval
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_eval.pl <input_filename> <column_num> <expr>\n" if ($#ARGV+1 < 3);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $count = 0;
my $line;
my @tok;
while ($line = <INF>) {
	chomp $line;
	next if ($line =~ /^#/);
	@tok = split /\t/, $line;
	$count++ if (defined $tok[$COL] and eval("$tok[$COL] $EXPR"));
}
close(INF);

print "$count\n";

exit;

