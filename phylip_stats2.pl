#!/usr/bin/env perl
#
# Prints statistics on variation for all phylip files in current directory.  
#
# Matt 3/7/11
# -----------------------------------------------------------------------------

use warnings;
use strict;

my @files = <*.phylip>;
die "No .phylip files found in current directory!" if (@files == 0);

my $numFiles = @files;
my $avgLen = 0;
my $avgMissing = 0;
my $avgVariants = 0;
my $avgMissingVariants = 0;

foreach my $file (sort @files) {
	my %seq;
	my $len;
	
	# Load sequences from file
	open INF,"<$file" or die "Can't open file: $file\n";
	while (<INF>) {
	    chomp;
	    if (/^(\w+)\s+(\w+)/) { # Start of new section
	    	$seq{$1} = $2;
	    	$len = length $2 if (not defined $len);
	    }
	}
	close INF;
	
	# Count variants
	my $missing = 0;
	my $variants = 0;
	my $missingVariants = 0;
	
	for (my $i = 0;  $i < $len;  $i++) {
		my %types;
		my $hasN = 0;
		foreach my $s (values %seq) {
			my $c = substr($s, $i, 1);
			if ($c eq 'N') {
				$hasN = 1;
				next;
			}
			$types{$c}++;
		}
		$missing++ if ($hasN);
		$variants++ if (keys %types > 1);
		$missingVariants++ if ($hasN and keys %types > 1);
	}
	
	$avgLen += $len;
	$avgMissing += $missing;
	$avgVariants += $variants;
	$avgMissingVariants += $missingVariants;
	my ($name) = $file =~ /(\S+)\.phylip/;
	print "$name\tLength:$len\tVars:$variants\tMissing:$missing\tMissing vars:$missingVariants\n";
}

print "\nAvg length: " . int($avgLen / $numFiles) . "\n";
print "Avg variants: " . int($avgVariants / $numFiles) . "\n";
print "Avg missing: " . int($avgMissing / $numFiles) . "\n";
print "Avg missing variants: " . int($avgMissingVariants / $numFiles) . "\n";

exit;