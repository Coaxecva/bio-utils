#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	4/18/12
#------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

use warnings;
use strict;

# Blat PSL format:
#   1. matches - Number of bases that match that aren't repeats
#   2. misMatches - Number of bases that don't match
#   3. repMatches - Number of bases that match but are part of repeats
#   4. nCount - Number of 'N' bases
#   5. qNumInsert - Number of inserts in query
#   6. qBaseInsert - Number of bases inserted in query
#   7. tNumInsert - Number of inserts in target
#   8. tBaseInsert - Number of bases inserted in target
#   9. strand - '+' or '-' for query strand. In mouse, second '+'or '-' is for genomic strand
#  10. qName - Query sequence name
#  11. qSize - Query sequence size
#  12. qStart - Alignment start position in query
#  13. qEnd - Alignment end position in query
#  14. tName - Target sequence name
#  15. tSize - Target sequence size
#  16. tStart - Alignment start position in target
#  17. tEnd - Alignment end position in target
#  18. blockCount - Number of blocks in the alignment
#  19. blockSizes - Comma-separated list of sizes of each block
#  20. qStarts - Comma-separated list of starting positions of each block in query
#  21. tStarts - Comma-separated list of starting positions of each block in target 
  
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
	
	my $matches = $length-$mismatches;
	
	my @psl;
	$psl[0] = $matches;
	$psl[1] = $mismatches;
	$psl[2] = 0;
	$psl[3] = 0;
	$psl[4] = 0;
	$psl[5] = 0;
	$psl[6] = 0;
	$psl[7] = 0;
	$psl[8] = '+';
	$psl[9] = $query;
	$psl[10] = 0;
	$psl[11] = $qstart;
	$psl[12] = $qend;
	$psl[13] = $subject;
	$psl[14] = 0;
	$psl[15] = $sstart;
	$psl[16] = $send;
	$psl[17] = 1;
	$psl[18] = $length;
	$psl[19] = 0;
	$psl[20] = $sstart;
	
	print join("\t", @psl) . "\n";
}

exit;

#-------------------------------------------------------------------------------
