#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Prints the unmapped reads to stdout in FASTQ format.
# Author:	mdb
# Created:	1/6/11
#------------------------------------------------------------------------------
my $BAM_INPUT_FILE = $ARGV[0];
my $FASTQ_INPUT_FILE = $ARGV[1];
#-------------------------------------------------------------------------------

use strict;

use Bio::DB::Sam;

die "Usage:  bam_get_reads.pl <bam file> <fastq file>\n" if ($#ARGV+1 < 2);

#
# Get mapped read IDs from BAM file
#

my $sam = Bio::DB::Sam->new(-bam => $BAM_INPUT_FILE);

my @refs = $sam->seq_ids;
my %reads;

foreach my $ref (@refs) {
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	
	foreach my $r (@matches) {
		my $name =  $r->query->name;
		$reads{$name} = 1;
	}
}

undef $sam;

#
# Extract reads from FASTQ not in BAM file
#

open(INF, $FASTQ_INPUT_FILE) or 
	die("Error: cannot open file '$FASTQ_INPUT_FILE'\n");

while (<INF> ) {
    if (/^\@(\S+)\//) { # header
    	my $seqID = $1;
		my $seq   = <INF>;
	    my $line3 = <INF>;
	    my $qual  = <INF>;

		if (not defined $reads{$seqID}) {
			print '@' . $seqID . "\n" . $seq . $line3 . $qual;
		}
    }
}
close(INF);

exit;

#-------------------------------------------------------------------------------


