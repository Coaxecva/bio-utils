#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/31/12
#-------------------------------------------------------------------------------
my $INCREMENT = 1000;
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

my %sizes;
my $len;
my $numSections = 0;

while (my $line = <>) {
    chomp $line;
    
    if ($line =~ /^>(.+)/) { # Start of new section
    	$sizes{$len}++ if (defined $len);
    	
        # Reset loop
        $len = 0;
        $numSections++;
    }
    else { # Sequence data
    	$len += () = $line =~ /\S+/g; # because of Windows end-of-line
    }
}

# Do last section
$sizes{$len}++ if (defined $len);

print "Num sections: $numSections\n";
print make_histogram2(\%sizes, undef, $INCREMENT, "-si");

exit;
#-------------------------------------------------------------------------------
