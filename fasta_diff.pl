#!/usr/bin/perl
#
#
# Matt 10/18/11
#
# Program params --------------------------------------------------------------
my $INF1 = $ARGV[0];  # input file name 
my $INF2 = $ARGV[1];  # input file name 
my $GENE_LIST = $ARGV[2];  # optional list of gene names
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_diff.pl <file1> <file2> [names]\n" if ($#ARGV+1 < 2);

my $pNames;
$pNames = loadList($GENE_LIST) if (defined $GENE_LIST);
my $pSeq1 = loadFASTAorPHYLIP($INF1, $pNames);
my $pSeq2 = loadFASTAorPHYLIP($INF2, $pNames);
print "Loaded " . (keys %$pSeq1) . " " . (keys %$pSeq2) . "\n";

my $compared = 0;

foreach my $name (sort keys %$pSeq1) {
	my $mismatch = 0;
	my $match = 0;
	my $miscall = 0;

	$compared++;
#	if ($pSeq1->{$name} ne $pSeq2->{$name}) {
#		#print "$name\n";
#		$mismatch++;
#	}

	for (my $i = 0;  $i < length $pSeq1->{$name};  $i++) {
		my $b1 = substr($pSeq1->{$name}, $i, 1);
		my $b2 = substr($pSeq2->{$name}, $i, 1);
		
		if ($b1 ne 'N' and $b2 ne 'N') {
			if ($b1 eq $b2) {
				$match++;
			}
			else {
				$mismatch++;	
			}
		}
		elsif ($b1 ne 'N' and $b2 eq 'N') {
			$miscall++;
		}
	}
	
	print "$name match=$match mismatch=$mismatch miscall=$miscall " . ($mismatch+$miscall > 0 ? '!!!!!!' : '') . "\n";# if ($mismatch+$miscall > 0);
	last if ($mismatch+$miscall > 0);
}

print "Compared: $compared\n";

exit;

#-------------------------------------------------------------------------------
sub loadList {
	my $filename = shift;
	my %out;
	
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	while (<$fh>) {
		chomp;
		my ($name) = split(/\t/);
		$out{$name}++;
	}
	close($fh);
	
	return \%out;
}

sub loadFASTAorPHYLIP {
	my $filename = shift;
	my $pNames = shift; # optional ref to hash of names
	my %out;
		
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $name;
	while (my $line = <$fh>) {
		chomp $line;
		if ($line =~ /^\>(\S+)/) { # FASTA header
			$name = $1;
			die "Error: sequences with same name in input file\n" if (defined $out{$name});
		}
		elsif ($line =~ /^(\S+)\s+(\S+)/) { # PHYLIP header & data
			$name = $1;
			die "Error: sequences with same name in input file\n" if (defined $out{$name});
			$out{$name} = $2;
		}
		else { # FASTA data
			die "loadFASTA: parse error" if (not defined $name);
			my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
			$out{$name} .= $s if (defined $s and (not defined $pNames or defined $pNames->{$name}));
		}
	}
	close($fh);
	
	return \%out;
}
