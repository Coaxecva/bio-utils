#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	
# Author:	mdb
# Created:	10/11/10
#-------------------------------------------------------------------------------
my $MIN_BASE_QUAL = 20;	# definition of HQ (High Quality) PHRED score
   $MIN_BASE_QUAL += 33; # scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;
use lib "/home/mbomhoff/scripts";
use histogram;

if (@ARGV == 0) {
	die "Usage: fastq_stats.pl <mode> <fastq_file>\n" .
		"   mode 0: # reads, mean quality, mean length, mean # N's\n" .
		"   mode 1: distribution of num N's\n" .
		"   mode 2: distribution of lengths\n" .
		"   mode 3: distribution of num HQ bases\n" . 
		"   mode 4: count reads that start or end with N\n" .
		"   mode 5: distribution of base quality scores\n" .
		"   mode 6: mean base quality per position (N's excluded)\n" .
		"   mode 7: num of reads with >= 20 HQ bases\n" .
		"   mode 8: distribution of mean read quality\n" . 
		"   mode 9: distribution of num N's by position\n";
}

my $MODE = shift @ARGV;
my @files;
if (@ARGV == 0) {
	@files = <*.fastq>;
}
else {
	push @files, @ARGV;
}

my $totalReads = 0;
my $totalLength = 0;
my $totalQual = 0;
my $totalNs = 0;
my @counts;
my $count = 0;
my %hashCount;

foreach my $file (@files) {
	open(INF, $file) or 
		die("Error: cannot open file '$file'\n");
	
	my $line;
	while( $line = <INF> ) {
	    if ($line =~ /^\@/) { # header
	    	#my $seqID = $line;   chomp $seqID;
			my $seq   = <INF>;   chomp $seq;
		    my $line3 = <INF>;   #chomp $line3;
		    my $qual  = <INF>;   chomp $qual;
		    
		    #die "Invalid record (length seq != length qual)" if (length $seq != length $qual);
		    
		    if ($MODE == 0) {
		    	my $sumQual = 0;
		    	foreach my $c (unpack("C*", $qual)) {
		    		$sumQual += $c;
		    	}
		    	$totalLength += length($qual);
		    	$totalQual += ($sumQual/length($qual));
		    	#$totalNs += countNs($seq);
		    }
			elsif ($MODE == 1) {
		    	#push @counts, countNs($seq);
		    	#my $count = countNs($seq);
		    	my $count = () = $seq =~ /N/g;
		    	$hashCount{$count}++;
			}
			elsif ($MODE == 2) {
				#push @counts, length($seq);
				my $count = length($seq);
		    	$hashCount{$count}++;
			}
			elsif ($MODE == 3) {
				#push @counts, countHQ($seq, $qual);
				my $count = countHQ(\$seq, \$qual);
				$hashCount{$count}++;
			}
			elsif ($MODE == 4) {
				my $first = substr($seq, 0, 1);
				my $last = chop $seq;
				$count++ if ($first eq 'N' or $last eq 'N');
			}
			elsif ($MODE == 5) {
				foreach my $c (unpack("C*", $qual)) {
					$hashCount{$c}++;
					$count++;
				}
			}
			elsif ($MODE == 6) {
				$count++;
				my @array_seq = split(//, $seq);
				my @array_qual = unpack("C*", $qual);
				for (my $pos = 0;  $pos < length $seq;  $pos++) {
					if ($array_seq[$pos] ne 'N') {
						$counts[$pos] += ($array_qual[$pos]-33);
					}
				}
			}
			elsif ($MODE == 7) {
				my $numHQ = countHQ($seq, $qual);
				$count++ if ($numHQ >= 20);
			}
			elsif ($MODE == 8) {
		    	my $sumQual = 0;
		    	foreach my $c (unpack("C*", $qual)) {
		    		$sumQual += $c-33;
		    	}
		    	push @counts, ($sumQual/length($qual));			
			}
			elsif ($MODE == 9) {
				$count++;
				my @array_seq = split(//, $seq);
				for (my $pos = 0;  $pos < length($seq);  $pos++) {
					if ($array_seq[$pos] eq 'N') {
						push @counts, $pos;
					}
				}
			}
		    
		    $totalReads++;
		    #print "$totalReads\r" if ($totalReads % 100000 == 0);
	    }
	}
	close(INF);
}

print "Total reads: $totalReads\n";
print "Count: $count\n";
if ($MODE == 0) {
	print "Mean base quality: " . (($totalQual/$totalReads)-33) . "\n";
	print "Mean length: " . ($totalLength/$totalReads) . "\n";
	#print "Mean # N's: " . ($totalNs/$totalReads) . "\n";
}
elsif ($MODE >= 1 and $MODE <= 3) {
	print make_histogram2(\%hashCount, undef, 1);
}
elsif ($MODE == 6) {
	for (my $pos = 0;  $pos < @counts;  $pos++) {
		print "$pos\t" . int($counts[$pos] / $count) . "\n";
	}
}
#else {
#	print make_histogram(\@counts, undef, 1) if (scalar @counts > 0);	
#}

exit;

#-------------------------------------------------------------------------------
sub countNs {
	my $seq = shift;
	my $count = 0;
	
	my @as = split(//, $seq);
	for (my $i = 0;  $i < length $seq;  $i++) {
		$count++ if ($as[$i] eq 'N');
	}
	
	return $count;
}
#-------------------------------------------------------------------------------
sub countHQ {
	my $pseq = shift;
	my $pqual = shift;
	
	my @as = split(//, $$pseq);
	my @aq = unpack("C*", $$pqual);
	
	my $count = 0;
	for (my $i = 0;  $i < length $$pseq;  $i++) {
		$count++ if ($aq[$i] >= $MIN_BASE_QUAL and $as[$i] ne 'N');
	}
	
	return $count;
}
#-------------------------------------------------------------------------------
