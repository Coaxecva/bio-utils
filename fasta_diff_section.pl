#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	3/15/12
#------------------------------------------------------------------------------
my $INF1 = $ARGV[0];  		# input filename 
my $INF2 = $ARGV[1];  		# input filename
my $SECTION = $ARGV[2];		# section name
my $START = $ARGV[3];		# optional 0-based start
my $END = $ARGV[4];			# optional 0-based end
my $SKIP_LEADING_Ns = 0;
my $IGNORE_Ns = 1;
# -----------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_diff_section.pl <file1> <file2> <section> [start end]\n" if ($#ARGV+1 < 3);

my $pSeq1 = loadFASTASection($INF1, $SECTION);
my $pSeq2 = loadFASTASection($INF2, $SECTION);

if (defined $START) {
	die "Need both start and end positions\n" if (not defined $END);
	my $len = $END-$START+1;
	my $s1 = substr($$pSeq1, $START, $len);
	my $s2 = substr($$pSeq2, $START, $len);
	$pSeq1 = \$s1;
	$pSeq2 = \$s2;
}

my ($skipN1, $skipN2) = (0, 0);
if ($SKIP_LEADING_Ns) {
	my ($leadingNs) = $$pSeq1 =~ /(^N+)/g;
	my $skipN1 = length($leadingNs);
	print "leading Ns: $skipN1\n";
	($leadingNs) = $$pSeq2 =~ /(^N+)/g;
	my $skipN2 = length($leadingNs);
	print "leading Ns: $skipN2\n";
}

if (length($$pSeq1) != length($$pSeq2)) {
	print "length mismatch " . length($$pSeq1) . " " . length($$pSeq2) . "\n";
}

my $mismatch = 0;
my $match = 0;
my $Ns = 0;

for (my $i = 0;  $i < length $$pSeq1;  $i++) {
	my $b1 = substr($$pSeq1, $i+$skipN1, 1);
	my $b2 = substr($$pSeq2, $i+$skipN2, 1);
	
	if ($b1 eq 'N' or $b2 eq 'N') {
		$Ns++;
		next if ($IGNORE_Ns);
	}
	
	if ($b1 eq $b2) {
		$match++;
	}
	else {
		$mismatch++;
		print "mismatch $i: $b1 $b2\n";
	}
}
	
print "match=$match mismatch=$mismatch Ns=$Ns\n";

exit;

#-------------------------------------------------------------------------------
sub loadFASTASection {
	my $filename = shift;
	my $secName = shift;
	my $out;
		
	open(my $fh, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $name;
	while (my $line = <$fh>) {
		chomp $line;
		if ($line =~ /^\>(\S+)/) { # FASTA header
			$name = $1;
		}
		else { # FASTA data
			die "loadFASTA: parse error" if (not defined $name);
			my ($s) = $line =~ /\S+/g; # because of Windows end-of-line
			$out .= $s if (defined $s and $name eq $secName);
		}
	}
	close($fh);
	
	return \$out;
}
