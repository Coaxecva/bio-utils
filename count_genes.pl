#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count the number of unique genes represented in a directory of
#           transcript sequence files.
# Author:	mdb
# Created:	2/28/11
#-------------------------------------------------------------------------------

use warnings;
use strict;

my @files = <*.phylip>;
die "No files found in current directory!" if (@files == 0);

my %genes;
foreach my $file (@files) {
	my ($name, $num) = $file =~ /(\S+)-(\S+)\.phylip/;
	next if (not $name);
	$genes{$name}++;
}

print "Genes: " . (keys %genes) . "\n";

exit;
