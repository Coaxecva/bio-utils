#!/usr/bin/env perl
 
use strict;

my %names;

my @files = <*.phylip>;
foreach my $file (@files) {
	my ($name) = $file =~ /^(\S+)\-(\d+)\.phylip/;
	$names{$name} = 1;
}

print "$_\n" foreach (keys %names);


