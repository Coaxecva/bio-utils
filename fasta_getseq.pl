#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Get a subsequence from a FASTA file.
# Author:	mdb
# Created:	9/13/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $SECTION = $ARGV[1]; # section name
my $START = $ARGV[2]; 	# 0-based start position in section
my $END = $ARGV[3];		# 0-based end position in section
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_getseq.pl <input_filename> <section> <start> <end>\n" if ($#ARGV+1 < 4);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");
	
my $pos;
my $seq;
my $name;
while (my $line = <INF>) {
	if ($line =~ /^\>(\S+)/) {
		$name = $1 if ($1 eq $SECTION);
		$seq = '';
		$pos = 0;
	}
    elsif (defined $name) {
    	chomp $line;
    	my $lineLen = length $line;
    	
		if ($pos > $END) {
			last;
		}
    	elsif ($pos >= $START or $pos+$lineLen-1 >= $START) {
    		my $offset = $START-$pos;
    		$offset = 0 if ($offset < 0 or $offset >= $lineLen);
    		my $len = $END-$pos+1;
    		$len = $lineLen if ($len >= $lineLen);
			$seq .= substr($line, $offset, $len);
    	}
        $pos += $lineLen;
    }
}
close(INF);

print fasta($seq) if ($seq);

exit;

#-------------------------------------------------------------------------------
sub fasta {
	my $in = shift;
	my $out;
	my $LINE_LEN = 80;
	
    while ($in) { # break up data into lines
    	$out .= substr($in, 0, $LINE_LEN) . "\n";
        substr($in, 0, $LINE_LEN) = "";
    }
    
    return $out;
}
