#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/3/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; # input filename
my $SKIP_LINES = $ARGV[1]; # optional row number, starting at 0
my $DELIMITER = "\t";
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  col_show.pl <input_filename> [row_num]\n" if (@ARGV < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
# Skip header
while (defined $SKIP_LINES and $SKIP_LINES--) {
	<INF>;
}

my $line = <INF>;
close(INF);

chomp $line;
my @tok = split(/$DELIMITER/, $line);
for (my $i = 0;  $i < @tok;  $i++) {
	my $base26 = toAlpha26($i);
	print "$i ($base26):\t$tok[$i]\n";
}

exit;
#-------------------------------------------------------------------------------

sub toAlpha26 {
	my $x = shift;
	
	return 'A' if ($x == 0);
	
	my $s = '';
	while ($x > 0) {
		my $n = $x % 26;
		$s = chr(65+$n) . $s;
		$x = int(($x-$n)/26);
	}
	
	return $s;
}

