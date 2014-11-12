#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Make sure FASTA seq lines are less than expected max length with no blanks.
# Author:	mdb
# Created:	3/16/12
#-------------------------------------------------------------------------------
my $MAX_LENGTH = 80;
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  file_line_length.pl <file>\n" if ($#ARGV+1 < 1);

my $INPUT_FILE = shift @ARGV;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $length;
while (my $line = <INF>) {
	next if ($line =~ /^\>/);
	chomp $line;
	die if (length($line) == 0);
	die "$line" if (length($line) > $MAX_LENGTH);
}
close(INF);

print "Line length:  $length\n";

exit;

#-------------------------------------------------------------------------------
