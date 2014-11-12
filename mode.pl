#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/19/11
#-------------------------------------------------------------------------------
my $INPUT_FILENAME = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  mode.pl <filename>\n" if (not $INPUT_FILENAME);

open(my $fh, $INPUT_FILENAME) or 
	die("Error: cannot open file '$INPUT_FILENAME'\n");

my $name;
while (my $line = <$fh>) {
	chomp $line;
	
	my %freq;
	for (my $i = 0;  $i < length($line);  $i++) {
		my $c = substr($line, $i, 1);
		$freq{$c}++;
	}
	
	my ($mode) = sort {$freq{$b} <=> $freq{$a}} keys %freq;
	print "Mode: $mode\n";
}

close($fh);

exit;
