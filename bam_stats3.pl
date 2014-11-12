#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Display histograms of various metrics for given BAM file.
# Author:	mdb
# Created:	1/20/11
#------------------------------------------------------------------------------
my $BAM_INPUT_FILE = $ARGV[0];
my $MODE = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

use lib "/home/mbomhoff/scripts";
use histogram;

if ($#ARGV+1 < 2) {
	die "Usage:  bam_stats.pl <bam file> <mode>\n" .
	    "   mode 0: histogram of read quality scores\n" .
	    "   mode 1: histogram of read mapping distances\n";
}

#
# Get mapped read IDs from BAM file
#

my $sam = Bio::DB::Sam->new(-bam => $BAM_INPUT_FILE);

my @refs = $sam->seq_ids;
my %reads;

my $buckets;
my $increment;

foreach my $ref (@refs) {
	my @matches = $sam->features(-type=>'match', -seq_id=>$ref);
	
	foreach my $r (@matches) {
		my $name =  $r->query->name;
		
		if ($MODE == 0) {
			$reads{$name} = $r->qual;
			$increment = 1;
		}
		elsif ($MODE == 1) {
			$reads{$name} = ($r->end - $r->start + 1);
			$increment = 76;
			#$buckets = 100;
		}
	}
}
undef $sam;

print histogram::make_histogram([values %reads], $buckets, $increment, 'si');

exit;

#-------------------------------------------------------------------------------


