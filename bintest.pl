#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Perform binomial test on given values
# Author:	mdb
# Created:	6/20/12
#------------------------------------------------------------------------------
my $val1 = $ARGV[0];
my $val2 = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Math::CDF qw{pbinom};

die "Usage:  bintest_table.pl <val1> <val2>\n" if (@ARGV < 2);

my $minor = ($val1 < $val2 ? $val1 : $val2);
my $total = $val1 + $val2;
my $p = pbinom($minor, $total, 0.5);
print "p-value: $p\n";

exit;

#-------------------------------------------------------------------------------
