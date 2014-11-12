#!/usr/bin/env perl
#
# Prints table of # bases for the all FASTA files in current directory.  
#
# Matt 4/25/11
# -----------------------------------------------------------------------------

use warnings;
use strict;
use List::Util qw(first);

my %lineNames;

my @files = <*.fasta>;
exit if (@files == 0);

# First get a list of all lines represented for all genes
foreach my $f (sort @files) {
	open INF,"<$f" or die "Can't open file: $f\n";
	while (<INF>) {
	    chomp;
	    if (/^\>\s*(\S+)/) { # Start of new section
	    	$lineNames{$1} = 1;
	    }
	}
	close INF;
}

# Print table header
my @lines = keys %lineNames;
print "Lines: @lines\n";
print "Gene Name\tTotal Sites\tSites With At Least One Line Covered\tSites With 50% Lines Covered\tSites With 90% Lines Covered\tSites With All Lines Covered\n";

# Count sites for each gene
my $numLines = scalar @lines;
foreach my $f (sort @files) {
	my ($prefix) = $f =~ /(\S+)\.fasta/;
	
	my $name;
	my %seq;
	
	open INF,"<$f" or die "Can't open file: $f\n";
	while (my $line = <INF>) {
	    chomp $line;
	    if ($line =~ /^\>\s*(\S+)/) { # Start of new section
	    	$name = $1;
	    }
	    else {
	    	$seq{$name} .= $line;	
	    }
	}
	close INF;
	
	my $covered = 0;
	my $covered50 = 0;
	my $covered90 = 0;
	my $covered100 = 0;
	my $len = length first {defined($_)} values %seq;
	
	for (my $i = 0;  $i < $len;  $i++) {
		my $count = 0;
		foreach my $name (keys %seq) {
			my $c = substr($seq{$name}, $i, 1);
			$count++ if ($c ne 'N');
		}
		$covered++ if ($count > 0);
		$covered50++ if ($count >= (0.5 * $numLines));
		$covered90++ if ($count >= (0.9 * $numLines));
		$covered100++ if ($count == $numLines);
		die if ($count > $numLines); # sanity check
	}
	next if ($covered == 0);
	print "$prefix\t$len\t$covered\t$covered50\t$covered90\t$covered100\n";
}

exit;

#-------------------------------------------------------------------------------
