#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Calculate the qvalues for the pvalues in the specified column.
# Author:	mdb
# Created:	2/20/12
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input filename
my $COL = $ARGV[1]; 		# column number, starting at 0
my $SKIP_LINES = $ARGV[2];	# optional number of header lines to skip
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Statistics::R;

die "Usage:  col_mean.pl <filename> <column> [skip_lines]\n" if (@ARGV < 2);

# Load pvalues from file
my $pvalues;
open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
while (defined $SKIP_LINES and $SKIP_LINES--) {
	<INF>;
}
while (<INF>) {
	next if (/^#/);
	chomp;
	my @tok = split /\t/;
	my $pval = $tok[$COL];
	next if (not defined $pval or $pval eq '');
	push @$pvalues, $pval;
}
close(INF);

# Create a communication bridge with R and start R
my $R = Statistics::R->new();
  
# Compute qvalues in R
my $cmds = <<END_OF_R;
library(qvalue,lib.loc='/home/mbomhoff/R/x86_64-redhat-linux-gnu-library')
r <- qvalue(p, lambda=0)
END_OF_R
$R->set('p', $pvalues);
my $out = $R->run($cmds);
my $qvalues = $R->get('r$qvalues');
foreach my $q (@$qvalues) {
	print "$q\n";
}

$R->stop();
exit;
