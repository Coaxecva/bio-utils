#!/usr/bin/perl
#
# Split FASTA file sections into separate files.  
#
# Matt 4/24/08
#
# Program params --------------------------------------------------------------
my $INPUTF = $ARGV[0];  # input file name
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_split.pl <input_filename>\n" if ($#ARGV+1 < 1);

open INPUTF,"<$INPUTF" or die "Can't open output file: $INPUTF\n";

my $line;
my $filename = "";
while ($line = <INPUTF>) {
    if ($line =~ /^\>\s*(\w+)/) { # Start of new section
		close OUTPUTF if ($filename ne "");
		$filename = $1 . ".fasta";
		open OUTPUTF,">$filename" or die "Can't open output file: $filename\n";
	}
	print OUTPUTF $line;
}

close INPUTF;

exit;
