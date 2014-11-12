#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	1/5/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $LOCATION = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Bio::DB::Sam;

die "Usage:  bam_get_reads.pl <input_filename> [chr:start:end]\n" if ($#ARGV+1 < 1);

my ($chr, $start, $end) = split(/:/, $LOCATION);

my $sam = Bio::DB::Sam->new(-bam => $INPUT_FILE, -autoindex => 1);

foreach my $ref ($sam->seq_ids) {
	my @matches;
	
	if (defined $LOCATION) {
		next if ($ref ne $chr);
		@matches = $sam->get_features_by_location(-type=>'match', -seq_id=>$ref, -start=>$start, -end=>$end);
	}
	else {
		@matches = $sam->features(-type=>'match', -seq_id=>$ref);
	}
	
	foreach my $r (@matches) {
		my $qual = qualEncode([$r->query->qscore]);
		print '@' . $r->query->name . "\n" .
				($r->strand < 0 ? reverseComplement($r->query->dna) : $r->query->dna) . "\n" .
				"+\n" .
				($r->strand < 0 ? reverse($qual) : $qual) . "\n";
	}
}

exit;

#-------------------------------------------------------------------------------
sub reverseComplement {
	my $s = shift;
	
	$s =~ tr/[AGCT]/[TCGA]/;
	$s = reverse($s);
	
	return $s;
}

sub qualEncode {
	my $pArray = shift;
	
	for (my $i = 0;  $i < @$pArray;  $i++) {
		$pArray->[$i] += 33;	
	}
	
	return pack('C*', @$pArray);
}

