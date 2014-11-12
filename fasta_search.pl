#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:  
# Author:	mdb
# Created:	5/25/12
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0]; 	# input FASTA file
my $INPUT_SEQ = $ARGV[1];	# input query sequence
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_search.pl <fasta> <seq>\n" if (@ARGV < 1);

my $pSeq = loadFASTA($INPUT_FILE);

foreach my $secName (keys %$pSeq) {
	if ($pSeq->{$secName} =~ /$INPUT_SEQ/) {
		print "$secName\n";	
	}	
}

exit;

#-------------------------------------------------------------------------------
sub loadFASTA {
	my $filename = shift;
	my %out;
		
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $count = 0;
	my $id;
	while (my $line = <$fh>) {
		chomp $line;
		next if (length($line) == 0); # skip blanks
		if ($line =~ /^\>(.+)/) { # FASTA header
			$id = $1;
			die if (not defined $id);
			die "Error: sequences with same name '$id' in input file\n" if (defined $out{$id});
		}
		else { # FASTA data
			die "loadFASTA: parse error" if (not defined $id);
			my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
			$out{$id} .= $s if (defined $s);
		}
	}
	close($fh);
	
	return \%out;
}

sub reverseComplement {
	my $p = shift; # reference to string
	
	$$p =~ tr/[AGCTBDHKMRSWVY]/[TCGAVHDMKYSWBR]/;
	$$p = reverse($$p);
}