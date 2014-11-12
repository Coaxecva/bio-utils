#!/usr/bin/perl
#
#
# Matt 10/18/10
#
# Program params --------------------------------------------------------------
my $INF = $ARGV[0];  # input file name 
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  phylip_diff.pl <input_filename>\n" if ($#ARGV+1 < 1);

my $len = 0;
my $line;
my %seq;
my $s;
my $name;

open INF,"<$INF" or die "Can't open file: $INF\n";
<INF>; # skip first line of phylip format
while ($line = <INF>) {
    chomp $line;
    
    if ($line =~ /^(\S+)\s+(\S+)/) {
    	$name = $1;
		$s = $2;
        $len = max($len, length $s);
        push @{$seq{$name}}, split(//,$s);	
    }
}
close INF;

$len = max($len, length $s);
push @{$seq{$name}}, split(//,$s);	

for (my $i = 0;  $i < $len;  $i++) {
	my $c;
	my $mismatch = 0;
	$s = '';
	
	foreach my $name (sort keys %seq) {
		my @a = @{$seq{$name}};
		$s .= "$name:$a[$i] ";
		if ($a[$i] ne 'N') {
			$c = $a[$i] if (not defined $c);
			if ($a[$i] ne $c) {
				$mismatch = 1;
			}
		}
	}
	
	print (($i+1) . ": $s\n") if ($mismatch);
}

exit;

#-------------------------------------------------------------------------------
sub max {
	my $x = shift;
	my $y = shift;
	
	return $x if ($x >= $y);
	return $y;
}
