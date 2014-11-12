#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	9/15/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  sam_stats.pl <input_filename>\n" if ($#ARGV+1 < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $numAlignments = 0;
my $duplicates = 0;
my %queryNames;
my %refNames;

my $line;
while ($line = <INF>) {
    chomp $line;
    
    if ($line =~ /^\@/) { # header
    	next;
    }
    else { # alignment
    	#print "$line\n";
    	my $line2 = <INF>;
    	my $line3 = <INF>;
    	my $line4 = <INF>;
    	
    	my @tok = split /\t/, $line;
    	my $query = $tok[0];
    	my $ref = $tok[2];
    	
    	if ($query ne "*" and $ref ne "*") {
    		$duplicates++ if (exists $queryNames{$query});
    		$queryNames{$query}++;
   			$refNames{$ref}++;	
    		$numAlignments++;	
    	}
    }
}

print "Num references: " . (scalar keys %refNames) . "\n";
foreach my $k (sort keys %refNames) {
	print "   $k ($refNames{$k})\n";
}
print "Num queries:    " . (scalar keys %queryNames) . "\n";
print "Dup queries:    $duplicates\n";
print "Num alignments: $numAlignments\n";

close(INF);
exit;

#-------------------------------------------------------------------------------
