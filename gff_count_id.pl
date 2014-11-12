#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	2/23/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------
	
use warnings;
use strict;

die "Specify annot filename" if (@ARGV < 1);

my $pID = loadGFF($INPUT_FILE);

print "Unique gene_id's: " . (keys %$pID) . "\n";

exit;

#-------------------------------------------------------------------------------
sub loadGFF {
	my $filename = shift;
	my %out;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);

		# Parse name from attributes field
		my ($id) = $attr =~ /gene_id \"(\S+)\"/;
		$out{$id}++;
	}
	close(INF);
	
	return \%out;
}
