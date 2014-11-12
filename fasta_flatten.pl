#!/usr/bin/perl
#
#
# Matt 10/21/10
#
# Program params --------------------------------------------------------------
my $INF = $ARGV[0];  # input file name 
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_flatten.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $line;
my $secCount = 0;

open INF,"<$INF" or die "Can't open file: $INF\n";
while ($line = <INF>) {
    chomp $line;
    
	if ($line =~ /^\>(\S+)/) { # Start of new section
		print "\n" if ($secCount > 0);
		print "$1\t";
		$secCount++;
	}
	else {
		print $line;
	}
}
print "\n";
close INF;
exit;
