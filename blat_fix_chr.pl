#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/16/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  blat_fix_chr.pl <filename>\n" if (@ARGV < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

#my $pastHeader = 0;
while (my $line = <INF>) {
#	if (not $pastHeader) {
#		print $line;
#		$pastHeader = 1 if ($line =~ /^\-\-\-\-\-/);
#		next;
#	}
	
	chomp $line;
	my @tok = split(/\t/, $line);
	$tok[13] = 'chr' . $tok[13];
	print join("\t", @tok) . "\n";
}
close(INF);

exit;

