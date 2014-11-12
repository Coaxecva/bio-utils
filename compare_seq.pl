#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/10/11
#------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage: align.pl <seq1.phylip|fasta> <seq2.phylip|fasta> [sec_name]\n" if (@ARGV < 2);

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];
my $section = $ARGV[2];
my $seq1 = loadSeq($file1, $section);
my $seq2 = loadSeq($file2, $section);

if (length $seq1 != length $seq2) {
	"Warning: sequences of different length, " . (length $seq1) . " != " . (length $seq2) . ", assuming same start\n";
}

my $len = min(length $seq1, length $seq2);
my ($s, $s1, $s2, $s3);
my $matches = 0;
my $mismatches = 0;
my $Ns = 0;

for (my $i = 0;  $i < $len;  $i++) {
	my $c1 = substr($seq1, $i, 1);
	my $c2 = substr($seq2, $i, 1);
	
	$s1 .= $c1;
	if ($c1 eq 'N' or $c2 eq 'N') {
		$s2 .= ' ';
		$Ns++;
	}
	elsif ($c1 ne $c2) {
		$s2 .= '-';
		$mismatches++;
	}
	else {
		$s2 .= '|';
		$matches++;
	}
	$s3 .= $c2;
	
	if ((($i+1) % 80) == 0 or $i == length($seq1)-1) {
		$s .= "$s1\n$s2\n$s3\n\n";
		$s1 = $s2 = $s3 = '';
	}
}

print "$s";# if ($mismatches > 0);
print "Total bases: $len\n";
print "Matches:     $matches\n";
print "Mismatches:  $mismatches\n";
print "Ns:          $Ns\n";
print "Identity:    " . int(100*($len - $mismatches)/$len) . "\n";

exit;

#-------------------------------------------------------------------------------
sub loadSeq {
	my $filename = shift;
	my $secName = shift; # optional
	my ($ext) = $filename =~ /\.(\w+)/;
	
	die "Unrecognized file format '$ext'\n" if ($ext ne 'phylip' and $ext ne 'fasta');
	
	open INF,"<$filename" or die "Can't open file: $filename\n";
	 
	if ($ext eq 'phylip') {
		while (<INF>) {
		    chomp;
		    if (/^(\w+)\s+(\w+)/) { # Start of new section
		    	next if (defined $secName and $secName ne $1);
		    	close INF;
		    	return $2;
		    }
		}
	}
	elsif ($ext eq 'fasta') {
		my $name;
		my $out;
		while (my $line = <INF>) {
			chomp $line;
			if ($line =~ /^\>\s*(\S+)/) {
				last if (defined $name);
				next if (defined $secName and $secName ne $1);
				$name = $1;
			}
			elsif (defined $name) {
				my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
				$out .= $s if (defined $s);
			}
		}
		close INF;
		
		die "Error: section '$secName' not found in input file\n" if (defined $secName and not defined $out);
		
		return $out;
	}
}

sub min {
	my $x = shift;
	my $y = shift;
	
	return $x if (defined $x and $x <= $y);
	return $y;	
}