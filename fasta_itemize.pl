#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print char in fasta record by position, one per line.
# Author:	mdb
# Created:	1/11/11
#------------------------------------------------------------------------------
my $INF = $ARGV[0];  			# input file name
my $SECTION_NAME = $ARGV[1];	# section name
my $POSITION = $ARGV[2];		# optional 0-based position in section
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_itemize.pl <input_filename> <section name> [position]\n" if ($#ARGV+1 < 2);

my $name;
my $ofs;

open INF,"<$INF" or die "Can't open file: $INF\n";
while (my $line = <INF>) {
    chomp $line;
    
    next if (length($line) == 0); # blank line
    
	if ($line =~ /^\>(.*)/ and length($line) < 80)
	{ # Start of new section
		$name = $1;
		$ofs = 0;
	}
	elsif ($name eq $SECTION_NAME) {
		foreach (split(//,$line)) {
			if (not defined $POSITION or (defined $POSITION and $ofs == $POSITION)) {
				print "$name:$ofs:$_\n";
				goto DONE if (defined $POSITION);
			}
			$ofs++;
		}
	}
}
DONE:
close INF;
exit;
