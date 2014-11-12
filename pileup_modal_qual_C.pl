#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Extract HQ sequence for all chromosomes and print as fasta to stdout.
#           Equivalent to pileup_get_chr.pl but uses inline C for huge speedup.
# Author:	mdb
# History:
# 	3/14/12	Created
# 	3/15/12	Tested, equivalent to pileup_get_chr.pl
# 	3/15/12	Used to generate WT PWK genome for mapping F1 sample 52 to
#           determine per read error rate.
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename
my $CHROMOSOME = $ARGV[1];	# optional chromosome number
#-------------------------------------------------------------------------------
my $MIN_DEPTH = 6;			# minimum HQ read depth
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/workspace/Work";
use Pileup qw{pileup_to_modal_qual_fasta};

die "Usage:  pileup_get_chr_C.pl <pileup> [chromosome]\n" if (@ARGV < 1);

$CHROMOSOME = '' if (not defined $CHROMOSOME);
pileup_to_modal_qual_fasta($INPUT_FILE, $CHROMOSOME);

exit;

#-------------------------------------------------------------------------------
