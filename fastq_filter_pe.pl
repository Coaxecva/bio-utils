#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Filter paired-end FASTQ reads based on minimum number of HQ bases.
# Author:	mdb
# Created:	10/5/10
# Usage:    filter.pl [fastq_file]
#-------------------------------------------------------------------------------
my $MIN_BASE_QUAL = 20;	 	# definition of HQ (High Quality) PHRED score
   $MIN_BASE_QUAL += 33; 	# scale for FASTQ encoding
my $MIN_HQ_BASES = 20;	 	# minimum number of HQ non-N bases required
#my $MAX_READ_LENGTH = 75;	# trim longer reads to this length
#-------------------------------------------------------------------------------

use warnings;
use strict;

my @files;
if ($ARGV[0]) {
	push @files, $ARGV[0];
}
else {
	@files = <*.fastq>;	
}

foreach my $inputFile (@files) {
	$inputFile =~ /(\w+)\.fastq/;
	my $outputFile = "$1.filtered.fastq";
	
	open(INF, $inputFile) or 
		die("Error: cannot open file '$inputFile'\n");
		
	open(OUTF, '>', $outputFile) or 
		die("Error: cannot open file '$outputFile'\n");
	
	my $totalReads = 0;
	my $goodReads = 0;
#	my $trimmedReads = 0;
	my %reads1;
	my %reads2;
	
	my $line;
	while( $line = <INF> ) {
	    if ($line =~ /^\@/) { # header
	    	my $seqID = $line;
			my $seq   = <INF>;  chomp $seq;
		    my $line3 = <INF>;
		    my $qual  = <INF>;  chomp $qual;
		    
		    die "Error: invalid record '$seqID'" if (length $seq == 0 or length $seq != length $qual);
		    
			# Trim read
#		    if (length $seq > $MAX_READ_LENGTH) {
#			    $seq  = substr($seq,  0, $MAX_READ_LENGTH);
#			    $qual = substr($qual, 0, $MAX_READ_LENGTH);
#			    $trimmedReads++;
#		    }
		    
		    # Filter on number of good bases (excluding Ns)
		    if (countGoodBases($seq, $qual) >= $MIN_HQ_BASES) {
		    	print OUTF $seqID;
		    	print OUTF "$seq\n";
		    	print OUTF $line3;
		    	print OUTF "$qual\n";
		    	$goodReads++;
		    }
		    
		    $totalReads++;
		    #print "$totalReads\r" if ($totalReads % 10000 == 0);
	    }
	}
			
	close(INF);
	close(OUTF);
}

#print "Total reads: $totalReads\n";
#print "Good reads: $goodReads " . int(100*$goodReads/$totalReads) . "% (q=$MIN_BASE_QUAL, l=$MIN_HQ_BASES)\n";
#print "Trimmed reads: $trimmedReads\n";

exit;

#-------------------------------------------------------------------------------
sub countGoodBases {
	my $seq = shift;
	my $qual = shift;
	
	my @as = split(//, $seq);
	my @aq = unpack("C*", $qual);
	
	my $count = 0;
	for (my $i = 0;  $i < length $seq;  $i++) {
		$count++ if ($aq[$i] >= $MIN_BASE_QUAL and $as[$i] ne 'N');
	}

	return $count;
}
