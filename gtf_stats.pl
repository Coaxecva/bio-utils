#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Info on types/counts for given GFF/GTF file.
# Author:	mdb
# Created:	9/20/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gtf_stats.pl <input_filename>\n" if ($#ARGV+1 < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my $count = 0;
my %names;
my %types;
my %refs;
my $maxLen = 0;

my $line;
my @tok;
while( $line = <INF> ) {
	chomp $line;
	@tok = split /\t/,$line;
	my $ref    = $tok[0];
	my $type   = lc($tok[2]);
	my $start  = $tok[3];
	my $end    = $tok[4];
	my $strand = $tok[6];
	my $frame  = $tok[7];
	my $attr   = $tok[8];
	
	die "Error: invalid line in file\n" if (@tok < 9);
	
	# Parse name from attributes field
	my $name;
	if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
 		$name = $1;
	}
	
	my ($id) = $attr =~ /gene_id \"(\S+)\";/;
	
#	if ($type eq 'gene') {
#		if (defined $names{$name}) {
#			print "Warning: duplicate gene name '$name'\n";
#		}
#		$names{$name} = 1;
#	}
	$names{$name}{$id} = 1;
	
	# Validate coordinates
	if ($start > $end) {
		print "Warning: discarding '$name' due to invalid coordinates (start=$start, end=$end)\n";
		next;
	}
	
	# Extract chromosome number from reference name
	if ($ref =~ /chr(\w+)/) {
		$ref = $1;
	}
	
	my $len = $end - $start + 1;
	$maxLen = $len if ($len > $maxLen);
				
	$count++;
}
close(INF);

print "$count annotations loaded, max length $maxLen\n";
print "Unique gene names: " . (keys %names) . "\n";

exit;
#-------------------------------------------------------------------------------

sub isOverlapping {
	my $a1 	= shift;
	my $a2 	= shift;
	
	return ($a1->{start} <= $a2->{end} and $a2->{start} <= $a1->{end});
}
