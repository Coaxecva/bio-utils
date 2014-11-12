#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/16/11
#-------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $OUTGROUP = 'merged_SPRET';
#my $OUTGROUP = 'CAROLI';
my %species = ( 
	'CAS' => [ 'CIM', 'CKN', 'CKS', 'CTP', 'DKN', 'MDG', 'MPR', 'sanger_CAST' ],
	'DOM' => [ 'BIK', 'BZO', 'DCP', 'DJO', 'DMZ', 'LEWES', 'WLA', 'sanger_WSB' ],
	'MUS' => [ 'BID', 'CZCH2', 'MBK', 'MBT', 'MCZ', 'MDH', 'MPB', 'merged_PWK' ]
);
#-------------------------------------------------------------------------------

use warnings;
use strict;
use List::Util qw(first);

die "Usage:  variants.pl <file.phylip>\n" if (@ARGV < 1);

my %seq;
loadPhylip($INPUT_FILE, \%seq);
die "Error: Sequence for outgroup '$OUTGROUP' not found in input file\n" if (not defined $seq{$OUTGROUP});

my $len = length( first { defined($_) } values %seq );
my @names = keys %seq;

print "All:\n";
my $count = 0;
for (my $i = 0;  $i < $len;  $i++) {
	my %types;
	my %bases;
	foreach my $name (@names) {
		my $c = substr($seq{$name}, $i, 1);
		goto NEXT if ($c eq 'N');
		$bases{$name} = $c;
		next if ($name eq $OUTGROUP);
		$types{$c}++;
	}
	if (keys %types > 1) { # is site variant?
		print "$count $i:\t" . (defined $bases{$OUTGROUP} ? $bases{$OUTGROUP} : '_') . ' ';
		foreach (sort keys %species) {
			foreach my $name (sort @{$species{$_}}) {
				print (defined $bases{$name} ? $bases{$name} : '_');
			}
			print ' ';
		}
		print "\n";
		$count++;
	}
	NEXT:
}

print "Synonymous:\n";
$count = 0;
for (my $pos = 0;  $pos < $len;  $pos+=3) {
	my %codons;
	foreach my $name (@names) {
		next if ($name eq $OUTGROUP);
		my $c = nt2aa( substr($seq{$name}, $pos, 3) );
		$codons{$c}++ if (defined $c);
	}
	
	if (keys %codons == 1) { # is site synonymous?
		for (my $i = 0;  $i < 3;  $i++) {
			my $pos2 = $pos + $i;
			my %types;
			my %bases;
			foreach my $name (@names) {
				my $c = substr($seq{$name}, $pos2, 1);
				goto NEXT2 if ($c eq 'N');
				$bases{$name} = $c;
				next if ($name eq $OUTGROUP);
				$types{$c}++;
			}
			if (keys %types > 1) { # is site variant
				print "$count $pos2:\t" . (defined $bases{$OUTGROUP} ? $bases{$OUTGROUP} : '_') . ' ';
				foreach (sort keys %species) {
					foreach my $name (sort @{$species{$_}}) {
						print (defined $bases{$name} ? $bases{$name} : '_');
					}
					print ' ';
				}
				print "\n";
				$count++;
			}
			NEXT2:
		}
	}
}

exit;

#-------------------------------------------------------------------------------
sub loadPhylip {
	my $filename = shift;
	my $pOut = shift;
	
	open INF,"<$filename" or die "Can't open file: $filename\n";
	while (<INF>) {
	    chomp;
	    if (/^(\w+)\s+(\w+)/) { # Start of new section
	        $pOut->{$1} = $2;
	    }
	}
	close INF;
}
#-------------------------------------------------------------------------------
# From SNAP.pl: converts input codon sequence to an amino acid character
sub nt2aa {
	my $codonStr = shift;
	return if (length $codonStr < 3); 
	
	my @aa_array = qw/ F F L L L L L L I I I M V V V V S S S S P P P P T T T T A A A A Y Y Z Z H H Q Q N N K K D D E E C C Z W R R R R S S R R G G G G/;
	my %baseToInt = (N => 0, T => 0, C => 1, A => 2, G => 3);
	
	my @codons = split(//, $codonStr);
	return if ($codons[0] eq 'N' or $codons[1] eq 'N');
	
	my $xleft  = $baseToInt{$codons[0]};
	my $xmid   = $baseToInt{$codons[1]};
	my $xright = $baseToInt{$codons[2]};
	die "nt2aa error: $codonStr @codons\n" if (not defined $xleft or not defined $xmid or not defined $xright);
	my $num = ($xmid*16) + ($xleft*4) + $xright;
	
	return $aa_array[$num];
}
