#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Merge FASTA/phylip files in a directory into one FASTA file.
# Author:	mdb
# Created:	11/14/11
#-------------------------------------------------------------------------------
my $OUTPUT_FILE = $ARGV[0];  # output file name
# ------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  fasta_merge.pl <output_filename>\n" if ($#ARGV+1 < 1);

open my $outf,">$OUTPUT_FILE" or die "Can't open output file: $OUTPUT_FILE\n";

my %seq;
foreach my $file (<*.phylip>) {
	my $p = loadFASTAorPHYLIP($file);
	my ($name) = $file =~ /(\S+\-\d+)\.\w+/;
	$seq{$name} = $p->{CIM};
}

foreach my $name (sort keys %seq) {
	print_fasta($outf, $name, \$seq{$name});
}

close $outf;

exit;
# ------------------------------------------------------------------------------
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

sub loadFASTAorPHYLIP {
	my $filename = shift;
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
			$out{$name} .= $s if (defined $s);
		}
	}
	close($fh);
	
	return \%out;
}
