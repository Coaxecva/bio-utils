#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Convert FASTQ file(s) to FASTA, print to stdout.
# Author:	mdb
# Created:	1/6/11
#-------------------------------------------------------------------------------
my $PREFIX = $ARGV[0];
$PREFIX = '' if (not defined $PREFIX);
#-------------------------------------------------------------------------------

use warnings;
use strict;

my @files;
#if (@ARGV >= 1) {
#	push @files, @ARGV;
#}
#else {
	@files = <$PREFIX*.fastq>;
#}

foreach my $file (@files) {
	open(my $inf, $file) or 
		die("Error: cannot open input file '$file'\n");
	
	while (<$inf>) {
	    if (/^\@(\S+)/) { # header
	    	my $seqID = $1;   	#chomp $seqID;
			my $seq   = <$inf>;	#chomp $seq;
		    my $line3 = <$inf>;	#chomp $line3;
		    my $qual  = <$inf>;	#chomp $qual;
			
		    print ">$seqID\n$seq";
	    }
	}
	
	close($inf);
}

exit;

#-------------------------------------------------------------------------------
