#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	5/30/12
#----------------------------------------------------------------------------------------------------------------------------------------------------------
my $MIN_GAP_SZ = 100;
my $MIN_SEQ_SZ = 1000;
#-------------------------------------------------------------------------------

use warnings;
use strict;

my $gapCount = 0;
my $seq = '';
my $seqID;

while (my $line = <>) {
    chomp $line;
    
    if ($line =~ /^>(.+)/) { # Start of new section
    	$seqID = $1;
    	if (length($seq) >= $MIN_SEQ_SZ) {
			count_Ns($seq);
    	}
    
        # Reset loop
        $seq = '';
    }
    else { # Sequence data
    	my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
    	$seq .= $s;
    }
}

# Do last section
if (length($seq) >= $MIN_SEQ_SZ) {
	count_Ns($seq);
}

exit;

#-------------------------------------------------------------------------------
sub count_Ns {
	my $s = shift;
	
    if (length($s) > 0) {
	   	my $n = 0;
	   	my $start;
	   	my $end;
	   	for (my $i = 0; $i < length($s); $i++) {
	   		my $c = substr($s, $i, 1);
	   		if ($c eq 'N') {
	   			$n++;
	   			$start = $i if (not defined $start);
	   		}
	   		else {
	   			if ($n >= $MIN_GAP_SZ) {
		   			$end = $i-1;
		   			print "$seqID\t.\tgap\t$start\t$end\t.\t+\t.\tID=gap$gapCount\n" ;
		   			$gapCount++;
	   			}
	   			$n = 0;
	   			undef $start;
	   		}
	   	}
    }	
}