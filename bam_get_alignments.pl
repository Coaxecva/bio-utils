#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/14/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $LOCATION = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Bio::DB::Sam;

die "Usage:  bam_get_alignments.pl <input_filename> [chr:start:end]\n" if ($#ARGV+1 < 1);

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
	
	my $minStart;
	foreach my $r (@matches) {
		$minStart = $r->start if (not defined $minStart);
		$minStart = $r->start if ($r->start < $minStart);
	}
	
	foreach my $r (@matches) {		
		my ($reference,$matches,$query) = $r->padded_alignment;
		my $pad = $r->start - $minStart;
		print ' ' x $pad . $r->query->name . "\n";
		print ' ' x $pad . "$reference\n";
		#print ' ' x $pad . "$matches\n";
		print ' ' x $pad . match($reference, $query) . "\n";
		print ' ' x $pad . "$query\n";
		print "\n";
	}
}

exit;

#-------------------------------------------------------------------------------
sub match {
	my $s1 = shift;
	my $s2 = shift;
	
	my @a1 = split(//, $s1);
	my @a2 = split(//, $s2);
	die if (@a1 != @a2);
	
	my $m;
	for (my $i = 0;  $i < @a1;  $i++) {
		if ($a1[$i] ne $a2[$i]) { $m .= '-'; }
		else { $m .= '|'; }
	}
	
	return $m;
}