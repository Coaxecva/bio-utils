#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Convert FASTQ file(s) to FASTA.
# Author:	mdb
# Created:	1/6/11
#-------------------------------------------------------------------------------

use strict;

my @files;
if (@ARGV >= 1) {
	push @files, @ARGV;
}
else {
	@files = <*.fastq>;
}

foreach my $file (@files) {
	open(my $inf, $file) or 
		die("Error: cannot open input file '$file'\n");
	
	my ($prefix) = $file =~ /(\S+)\.fastq/;
	my $outputFile = $prefix . '.fasta';
	
	open(my $outf, '>', $outputFile) or 
		die("Error: cannot open output file '$outputFile'\n");
	
	while (<$inf>) {
	    if (/^\@(.+)/) { # header
	    	my $seqID = $1;   	#chomp $seqID;
			my $seq   = <$inf>;	#chomp $seq;
		    my $line3 = <$inf>;	#chomp $line3;
		    my $qual  = <$inf>;	#chomp $qual;
			
		    print $outf ">$seqID\n$seq";
	    }
	}
	
	close($inf);
	close($outf);
}

exit;

#-------------------------------------------------------------------------------
