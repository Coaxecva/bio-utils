#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	2/18/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $NUM_LINES  = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  perl split_file.pl <input_file> <num_lines>\n" if (not $INPUT_FILE or not $NUM_LINES);

open INF, "<$INPUT_FILE" or die "Can't open file: $INPUT_FILE\n";

my $count = 1;
my @lines;

while (<INF>) {
	push @lines, $_;
	if (@lines >= $NUM_LINES) {
		my $filename = "$INPUT_FILE.$count";
		open OUTF, ">$filename" or die "Can't open file: $filename\n";
		print OUTF $_ foreach (@lines);
		close OUTF;
		$count++;
		@lines = ();
	}
}
close INF;

exit;
