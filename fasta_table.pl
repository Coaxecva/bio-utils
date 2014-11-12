#!/usr/bin/env perl
#
# Prints table of # bases for the all FASTA files in current directory.  
#
# Matt 4/14/11
# -----------------------------------------------------------------------------

use warnings;
use strict;

my $name;
my %seq;

my @files = <*.fasta>;
foreach my $f (sort @files) {
	my ($prefix) = $f =~ /(\S+)\.fasta/;
	
	open INF,"<$f" or die "Can't open file: $f\n";
	while (my $line = <INF>) {
	    chomp $line;
	    if ($line =~ /^\>(\S+)/) { # Start of new section
	    	$name = $1;
	    }
	    else { # Sequence data
	    	$seq{$name}{$prefix} .= $line;
	    }
	}
	close INF;
}

foreach my $name (sort keys %seq) {
	print "\t$name";	
}
print "\n";

foreach my $f (sort @files) {
	my ($prefix) = $f =~ /(\S+)\.fasta/;
	print "$prefix";
	
	foreach my $name (sort keys %seq) {
		if (defined $seq{$name}{$prefix}) {
			my $acgt = () = $seq{$name}{$prefix} =~ /[ACGT]/g;
			print "\t$acgt";
		}
		else {
			print "\t0";	
		}
	}
	
	print "\n";
}

exit;

#-------------------------------------------------------------------------------
