#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/26/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $REGION = $ARGV[1];  # chromosome:start:end
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  blat_filter_genes.pl <filename> <chromosome:start:end>\n" if (@ARGV < 2);

my ($chr, $rStart, $rEnd) = split(':', $REGION);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

#my $pastHeader = 0;
#while (not $pastHeader) {
#	my $line = <INF>;
#	print $line;
#	$pastHeader = 1 if ($line =~ /^\-\-\-\-\-/);
#}
	
while (my $line = <INF>) {
#	my ($matches) = $line =~ /^(\d+)/;
#	next if ($matches < 100);
	
	chomp $line;
	my @tok = split(/\t/, $line);
	my $tName = $tok[13];
#	if ($tName =~ /^chr(\S+)/) {
#		$tName = $1;	
#	}
	my $tStart = $tok[15];
	my $tEnd = $tok[16];
	
#	my @blockSizes = split(',', $tok[18]);
#	my @tStarts = split(',', $tok[20]);
	
	if ($chr eq $tName and $tStart >= $rStart and $tEnd <= $rEnd) {
		print "$line\n";
	}
}
close(INF);

exit;

