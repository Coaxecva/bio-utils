#!/usr/bin/env perl
#
# 
# -----------------------------------------------------------------------------
my $MIN_SEQ = 100;

use warnings;
use strict;

my $numN = 0;
my $secSize = 0;
my $n = 0;

while (my $line = <>) {
    chomp $line;
    
    if ($line =~ /^>/) { # Start of new section
    	$numN++ if ($secSize-$n < $MIN_SEQ);
    
        # Reset loop
        $secSize = 0;
        $n = 0;
    }
    else { # Sequence data
        $secSize += () = $line =~ /\S/g;
        $n += () = $line =~ /N/g;
    }
}

# Do last section
$numN++ if ($secSize-$n < $MIN_SEQ);

# Print totals
print "Num N: $numN\n";

exit;

#-------------------------------------------------------------------------------
