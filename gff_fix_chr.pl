#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Remove leading "chr" from reference names.
# Author:	mdb
# Created:	2/3/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_fix_chr.pl <file>\n" if ($#ARGV+1 < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $line;
my @tok;
while ($line = <INF>) {
	chomp $line;
	@tok = split /\t/,$line;
	($tok[0]) = $tok[0] =~ /chr(\w+)/;
	for (my $i = 0;  $i < @tok;  $i++) {
		print $tok[$i];
		print "\t" if ($i != $#tok);
	}
	print "\n";
}
close(INF);

exit;

