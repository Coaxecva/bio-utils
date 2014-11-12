#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/31/12
#-------------------------------------------------------------------------------
my $MIN_ALIGMENT_LENGTH = 350;
my $MIN_MATCHES = 350;
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

my %hits;
my %matches;
my %lengths;

while (<>) {
	chomp;
	my @tok = split(/\t/);
	my $query 		= $tok[0];
	my $subject     = $tok[1];
	my $pctIdent 	= $tok[2];
	my $length 		= $tok[3];
	my $mismatches 	= $tok[4];
	my $gaps 		= $tok[5];
	my $qstart 		= $tok[6];
	my $qend		= $tok[7];
	my $sstart 		= $tok[8];
	my $send 		= $tok[9];
	my $evalue 		= $tok[10];
	my $bitscore 	= $tok[11];
	
	next if ($length < $MIN_ALIGMENT_LENGTH);
	$lengths{$length}++;
	
	my $matches = $length-$mismatches;
	next if ($matches < $MIN_MATCHES);
	
	die if (not defined $query or not defined $subject);
	
	push @{$hits{$subject}{$query}}, { qstart => $qstart, qend => $qend, sstart => $sstart, send => $send, length => $length, ident => $pctIdent };
	$matches{$subject}{$query} += $matches;
}

foreach my $subject (sort keys %matches) {
	print "$subject:\n";
	foreach my $query (sort {$matches{$subject}{$b} <=> $matches{$subject}{$a}} keys %{$matches{$subject}}) {
		my $numHits = @{$hits{$subject}{$query}};
		print "   $query $numHits $matches{$subject}{$query}\n";
	}
}

print make_histogram2(\%lengths, undef, 10, "-si");

exit;
#-------------------------------------------------------------------------------
