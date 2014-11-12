#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Dump regions from pileup/VCF file that overlap CDS annotations
#           into one big FASTA file.
# Author:	mdb
# Created:	11/10/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup/VCF filename
my $OUTPUT_FILE = "transcripts.fasta";

my $ANNOT_FILE = '/data/genome/mus/ensembl61/combined.gtf';
my $ANNOT_BIN_SZ = 7000 ;

my $DATA_PATH = "/data/query/17o";

my $MIN_DEPTH = 6;
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_get_transcripts.pl <pileup>\n" if ($#ARGV+1 < 1);

# Get list of transcript files
my @files = <$DATA_PATH/*.phylip>; # must be transcripts (coding bases only), not genes!	
die "Error: no files found in '$DATA_PATH'" if (not @files);
my %transcripts;
foreach my $file (@files) {
	my ($name) = $file =~ /\S+\/(\S+\-\d+)\.\w+/;
	$transcripts{$name}++;
}

my ($pBins, $pTrans) = loadTranscripts($ANNOT_FILE, \%transcripts);

open(INF, $INPUT_FILE) or 
	die("Error: cannot open file '$INPUT_FILE'\n");

my %lastPos;
my %seq;

my $parsex  = qr/^\S+\t\S+\t\S+\t(\S+)\t\S+\t\S+\t\S+\t(\S+)/;
my $parsex2 = qr/^(\S+)\t(\S+)\t(\S+)\t\S+\t\S+\t\S+\t\S+\t\S+\t(\S+)\t(\S+)/;

my $count = 0;
$| = 1;

while (my $line = <INF>) {
	my ($base, $depth) = $line =~ $parsex;
	next if ($depth < $MIN_DEPTH or $base eq 'N');
	
	my ($ref, $pos, $refbase, $seq, $qual) = $line =~ $parsex2;
	
	print "$ref $pos              \r" if ((++$count % 100000) == 0);
	
	# Search all annotations
	foreach my $i (0, -1, 1) {
		my $bin = int($pos/$ANNOT_BIN_SZ) + $i;
		foreach my $a (@{$pBins->{$ref}{$bin}}) {
			if ($pos >= $a->{start} and $pos <= $a->{end}) { # overlapping
				if ($refbase eq '*' or length $base > 1 or 
					$base !~ /[ACGT]/ or
					countHQBases(\$seq, \$qual) < $MIN_DEPTH)
				{
					next;
				}
				
				my $name = $a->{name};
				$seq{$name}{$pos} = $base;
				# can't break here b/c of potential overlapping annotations
			}
		}
	}
}
close(INF);
print "\n";

$| = 0;
my %seq2;
foreach my $name (keys %seq) {
	foreach my $cds (sort {$a->{start} <=> $b->{start}} @{$pTrans->{$name}}) {
		for (my $pos = $cds->{start};  $pos <= $cds->{end};  $pos++) {
			if (defined $seq{$name}{$pos}) {
				$seq2{$name} .= $seq{$name}{$pos}	
			}
			else {
				$seq2{$name} .= 'N';
			}
		}
	}
}

open(my $fh, '>', $OUTPUT_FILE) or 
	die("Error: cannot open file '$OUTPUT_FILE'\n");
foreach my $name (sort keys %seq2) {
	print_fasta($fh, $name, \$seq2{$name});
}
close($fh);

exit;

#-------------------------------------------------------------------------------
# Using substr is tiny bit faster than split
sub countHQBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my $count = 0;
	
	my ($i, $j);
	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
		my $c = substr($$pseq, $i, 1);
		print STDERR "error 1: $i $j $$pseq $$pqual\n" if (not defined $c);
		
		if ($c eq '>' or $c eq '<') { # reference skip 
			$j++; # mdb added 10/18/11
			next;
		}
		elsif ($c eq '$') { # end of read
			next;
		}
		elsif ($c eq '^') { # start of read followed by encoded quality
			$i++;
			next;
		}
		elsif ($c eq '+' or $c eq '-') { # indel
			$c = substr($$pseq, $i+1, 1);
			if ($c =~ /\d/) {
				$i++;
				my $c2 = substr($$pseq, $i+1, 1);
				if ($c2 =~ /\d/) {
					my $n = int($c)*10 + int($c2);
					$i += $n + 1;
				}
				else {
					$i += $c;
				}
			}
			next;
		}
		
		my $q = ord(substr($$pqual, $j++, 1));
		print STDERR "error 2: $i $j $$pseq $$pqual\n" if (not defined $q);
		if ($q >= $MIN_BASE_QUAL) {
			$count++;
		}
	}
	die "error 3: $i $j $$pseq $$pqual" if ($i != length $$pseq or $j != length $$pqual);
	
	return $count;
}
#sub countHQBases {
#	my $pseq = shift;
#	my $pqual = shift;
#	
#	my $count = 0;
#	
#	my @as = split(//, $$pseq);
#	my @aq = unpack("C*", $$pqual);
#	
#	my ($i, $j);
#	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
#		my $c = $as[$i];
#		print STDERR "error 1: $i $j $$pseq $$pqual\n" if (not defined $c);
#		if ($c eq '>' or $c eq '<') { # reference skip 
#			$j++; # mdb added 10/18/11
#			next;
#		}
#		elsif ($c eq '$') { # end of read
#			next;
#		}
#		elsif ($c eq '^') { # start of read followed by encoded quality
#			$i++;
#			next;
#		}
#		elsif ($c eq '+' or $c eq '-') { # indel
#			$c = $as[$i+1];
#			if (isDigit($c)) {
#				$i++;
#				my $c2 = $as[$i+1];
#				if (isDigit($c2)) {
#					my $n = int("$c$c2");
#					$i += $n + 1;
#				}
#				else {
#					$i += $c;
#				}
#			}
#			next;
#		}
#		
#		my $q = $aq[$j++];
#		print STDERR "error 2: $i $j $$pseq $$pqual\n" if (not defined $q);
#		if ($q >= $MIN_BASE_QUAL and $c ne 'N') { # FIXME: really need to check for N?
#			$count++;
#		}
#	}
#	die "error 3: $i $j $$pseq $$pqual" if ($i != @as or $j != @aq);
#	
#	return $count;
#}
#-------------------------------------------------------------------------------
sub loadTranscripts {
	my $filename = shift;
	my $pTranscripts = shift;
	my %out;
	my %out2;
	
	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my @tok;
	while (<INF>) {
		chomp;
		@tok = split /\t/;
		my $ref   = $tok[0];
		my $type  = lc($tok[2]);
		my $start = $tok[3];
		my $end   = $tok[4];
		my $attr  = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'cds');
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding entry due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		# Parse name from attributes field
		my ($name) = $attr =~ /transcript_name \"(\S+)\";/;
		next if (not defined $pTranscripts->{$name});
		
		my $bin = int($start/$ANNOT_BIN_SZ);
		push @{ $out{$ref}{$bin} }, { name => $name, start => $start, end => $end };
		push @{ $out2{$name} }, { start => $start, end => $end };
		
		# Bins should be at least 1/3 size of largest annotation
		my $len = $end - $start + 1;
		die "Bin size $ANNOT_BIN_SZ is too small for $len" if ($len > $ANNOT_BIN_SZ*3);
	}
	close(INF);

	return (\%out, \%out2);
}
#-------------------------------------------------------------------------------
sub print_fasta {
	my $fh = shift;		# file handle
	my $name = shift;	# fasta section name
	my $pIn = shift; 	# reference to section data
	
	my $LINE_LEN = 80;
	my $len = length $$pIn;
	my $ofs = 0;
	
	print {$fh} ">$name\n";
    while ($ofs < $len) {
    	print {$fh} substr($$pIn, $ofs, $LINE_LEN) . "\n";
    	$ofs += $LINE_LEN;
    }
}
