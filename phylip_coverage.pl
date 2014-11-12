#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Take a phylip file that also has read depths after the sequence
#           and extract bases at the specified read depth or higher.
# Author:	mdb
# Created:	5/25/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];  # input filename
my $MIN_DEPTH = $ARGV[1];	# minimum read depth
my $DO_REV_COMP = 1; 		# flag to enable/disable reverse complement
my $ASCII_SCALE = 33;
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  phylip_coverage.pl <input_filename> <min_depth>\n" if ($#ARGV+1 < 2);

open(my $fh, "<$INPUT_FILE") or die "Can't open file: $INPUT_FILE\n";

my $name;
my $seq;
my $depths;
while (my $line = <$fh>) {
	chomp $line;
    if ($line =~ /^(.*)\t(.*)\t(.*)/) {
		$name = $1;
		$seq = $2;
		$depths = $3;
		last;
    }
}
close($fh);

die if (not defined $seq);
die if (not defined $depths);

my $s;
my @a = unpack("C*", $depths);
for (my $i = 0;  $i < @a;  $i++) {
	my $depth = $a[$i]-$ASCII_SCALE;
	if ($depth < $MIN_DEPTH) {
		$s .= 'N';
	}
	else {
		$s .= substr($seq, $i, 1);
	}
}
replaceAmbiguous(\$s);
reverseComplement(\$s) if ($DO_REV_COMP);
($name) = $INPUT_FILE =~ /\S+\_(\w+)\./;
print "$name\t$s\n";

exit;

#-------------------------------------------------------------------------------
sub replaceAmbiguous {
	my $p = shift; # reference to string
	$$p =~ s/[BDHKMRSWVXY]/N/g;
}

sub reverseComplement {
	my $p = shift; # reference to string
	$$p =~ tr/[AGCT]/[TCGA]/;
	$$p = reverse($$p);
}
