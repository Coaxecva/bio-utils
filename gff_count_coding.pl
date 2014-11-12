#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Print summary of # bases that are genic, intronic, exonic, & coding.
# Author:	mdb
# Created:	6/22/11
#------------------------------------------------------------------------------
my $DATA_PATH = '/data/query/2a';
my $GENE_NAME = $ARGV[0]; # optional
my @FILES = <$DATA_PATH/*.phylip>; # must be genes, not transcripts!
my $GTF_FILE = '/data/genome/mus/combined.gtf';
#-------------------------------------------------------------------------------
my %species = (
	'CAS' => [ 'CIM', 'CKN', 'CKS', 'CTP', 'DKN', 'MDG', 'MPR', 'sanger_CAST' ],
	'DOM' => [ 'BIK', 'BZO', 'DCP', 'DJO', 'DMZ', 'LEWES', 'WLA', 'sanger_WSB' ], 
	'MUS' => [ 'BID', 'CZCH2', 'MBK', 'MBT', 'MCZ', 'MDH', 'MPB', 'merged_PWK' ]
);
#-------------------------------------------------------------------------------
	
use warnings;
use strict;
use List::Util qw(first);

die "No files found in $DATA_PATH\n" if (@FILES == 0);

my $pGenes = loadGFF($GTF_FILE);

my %count;
foreach my $file (@FILES) {
	my ($geneName) = $file =~ /\S+\/(\S+)\.phylip/;
	next if (defined $GENE_NAME and $geneName ne $GENE_NAME);
	my $pSeq = loadPhylip($file);
	
	if ($pGenes->{$geneName}{strand} eq '-') {
		foreach (keys %$pSeq) {
			$pSeq->{$_} = reverse $pSeq->{$_};	
		}	
	}
	
	my $len = length( first {defined($_)} values %$pSeq );
	for (my $ofs = 0;  $ofs < $len;  $ofs++) {
		my %bases;
		foreach my $name (@{$species{'CAS'}}) {
			my $b = substr($pSeq->{$name}, $ofs, 1);
			goto NEXT if ($b eq 'N'); # skip to next site
			$bases{$b}++;
		}
		
		my $abs = $pGenes->{$geneName}{start} + $ofs;
		
		$count{'total'}++;
		
		foreach my $r (@{$pGenes->{$geneName}{exons}}) {
			if ($abs >= $r->{start} and $abs <= $r->{end}) {
				$count{'exonic'}++;
			}
			else {
				$count{'intronic'}++;
				goto NEXT;
			}
		}
		
		foreach my $r (@{$pGenes->{$geneName}{cds}}) {
			if ($abs >= $r->{start} and $abs <= $r->{end}) {
				$count{'coding'}++;
			}
			else {
				$count{'non-coding'}++;	
			}
		}
		
		NEXT:
	}
}

foreach (sort keys %count) {
	print "$_: $count{$_}\n";
}

exit;

#-------------------------------------------------------------------------------
sub loadPhylip {
	my $filename = shift;
	my %out;
		
	open(my $fh, "<$filename") or 
		die("Error: cannot open file '$filename'\n");
	
	while (<$fh>) {
		chomp;
		my @tok = split(/\s+/);
		die if (not defined $tok[0] or $tok[0] eq '' or not defined $tok[1] or $tok[1] eq '');
		$out{$tok[0]} = $tok[1];
	}
	
	close($fh);
	
	return \%out;
}

sub loadGFF {
	my $filename = shift;
	my %out;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(<INF>) {
		chomp;
		my @tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		
		if ($type eq 'gene') {
			$out{$name}{start} = $start;
			$out{$name}{end} = $end;
			$out{$name}{strand} = $strand;
		}
		elsif ($type eq 'exon') {
			push @{$out{$name}{exons}}, { start => $start, end => $end };
		}
		elsif ($type eq 'cds') {
			push @{$out{$name}{cds}}, { start => $start, end => $end };
		}
	}
	close(INF);
	
	return \%out;
}
