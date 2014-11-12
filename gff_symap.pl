#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	6/13/12
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
#-------------------------------------------------------------------------------
	
use warnings;
use strict;

die "Specify annot filename\n" if (@ARGV < 1);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
while(<INF>) {
	chomp;
	my @tok = split /\t/;
	my $type = lc($tok[2]);
	my $attr = $tok[8];

	die "Error: invalid line in file\n" if (@tok < 9);

	next if ($type ne 'gene' and
			 $type ne 'exon' and
			 $type ne 'cds' and
			 $type ne 'centromere' and
			 $type ne 'gap');
			 
	$tok[2] = $type; # convert to lowercase

	# Parse name from attributes field
	if ($type eq 'gene') {
		my ($id)   = $attr =~ /ID\=(\S+)/;
		my ($name) = $attr =~ /Name\=(\S+)/;
		my ($note) = $attr =~ /Note\=(\S+)/;
		$tok[8] = "ID \"$id\" ; Name \"$name\" ; Note \"$note\"";
	}
	elsif ($type eq 'exon') {
		my ($id)   = $attr =~ /gene_id \"(\S+)\"/;
		my ($name) = $attr =~ /gene_name \"(\S+)\"/;
		my ($note) = $attr =~ /transcript_name \"(\S+)\"/;
		$tok[8] = "ID \"$id\" ; Name \"$name\" ; Note \"$note\"";
	}
	
	print join("\t", @tok) . "\n";
}
close(INF);
	
exit;
#-------------------------------------------------------------------------------