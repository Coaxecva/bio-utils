#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	1/31/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $NAME = $ARGV[1];
#my $REF = $ARGV[1];
#my $POS = $ARGV[2];
#-------------------------------------------------------------------------------
my $REFSEQ = '/data/genome/mus/m_musculus_ncbi37.fa';
#-------------------------------------------------------------------------------

use warnings;
use strict;

use Bio::DB::Sam;

#die "Usage:  bam_get_single_read.pl <input_filename> <chromosome> <position>\n" if ($#ARGV+1 < 3);
die "Usage:  bam_get_single_read.pl <input_filename> <name>\n" if ($#ARGV+1 < 2);

my $sam = Bio::DB::Sam->new(-bam => $INPUT_FILE, -fasta=>$REFSEQ);

#my @matches = $sam->features(-type=>'match', -seq_id=>$REF);
my @matches = $sam->features(-type=>'match', -name=>$NAME);

foreach my $r (@matches) {
	my $name  = $r->query->name;
	my $ref   = $r->seq_id;
	my $start = $r->start;
	my $end   = $r->end;
	my $seq   = $r->query->dna;
	my @qual  = $r->qscore;
	my $cigar = $r->cigar_str;
	my $qscore = $r->qual;
	my ($r,$m,$q) = $r->padded_alignment;
	
	print "name:      $name\n";
	print "location:  $ref:$start:$end\n";
	print "cigar:     $cigar\n";
	print "score:     $qscore\n";
	print "$seq\n@qual\n";
	#print "$r\n$m\n$q\n";
}

exit;

#-------------------------------------------------------------------------------
