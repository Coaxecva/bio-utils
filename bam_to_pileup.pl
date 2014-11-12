#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Generates an unadulterated pileup from the input BAM file for
#           testing purposes, to compare SAMtools default pileup output to
#           raw BAM read depth.  SAMtools adjusts base quality values (BAQ
#           option) and removes "anomalous" reads (improperly paired) by
#           default.
# Author:	mdb
# History:
#    1/5/11		Created
#    3/29/12	Tested for F1-Pilot
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $LOCATION = $ARGV[1];
#-------------------------------------------------------------------------------
my $MIN_DEPTH = 6;
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Bio::DB::Sam;

die "Usage:  bam_to_pileup.pl <bam_file> [chr:start-end]\n" if ($#ARGV+1 < 1);

my $sam = Bio::DB::Sam->new(-bam => $INPUT_FILE, -autoindex => 1);

my $callback = sub {
	my ($seqid,$pos,$pileup) = @_;
	
	my $depth = @$pileup;
	return if ($depth < $MIN_DEPTH);
	
	my @bases;
	my @quals;
	for my $p (@$pileup) {
		next if $p->indel or $p->is_refskip; # exclude INDELs and ref skips
		
		my $a = $p->alignment;
		my $base  = substr($a->qseq,$p->qpos,1);
		next if $base =~ /[nN]/;
		push @bases, $base;
		
		my $score = $a->qscore->[$p->qpos];
		push @quals, chr($score+33);
	}
	
	$depth = @bases;
	if ($depth >= $MIN_DEPTH) {
		# mpileup format
		print "$seqid\t$pos\tN\t$depth\t" . join('', @bases) . "\t" . join('', @quals) . "\n";
	}
};

if (not defined $LOCATION) {
	foreach my $ref (sort $sam->seq_ids) {
		$sam->pileup($ref, $callback);
	}
}
else {
	$sam->pileup($LOCATION, $callback);
}

exit;

#-------------------------------------------------------------------------------
