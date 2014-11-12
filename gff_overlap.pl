#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Count overlapping genes
# Author:	mdb
# Created:	8/8/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my $DATA_SET = '17o';
my $DATA_PATH = "/data/query/$DATA_SET";
my $ANNOT_FILE = '/data/genome/mus/ensembl61/combined.gtf';
#-------------------------------------------------------------------------------

use warnings;
use strict;

my $pAnnot = loadGFF($ANNOT_FILE);

# Create subset of genes from query result
my %geneNames;
foreach my $file (<$DATA_PATH/*.phylip>) {
	my ($geneName) = $file =~ /\S+\/(\S+)\-\d+\.phylip/;
	$geneNames{$geneName}++;
}

print "Genes: " . (keys %geneNames) . "\n";

# Display count of overlapping annotations
my %seen;
my $count = 0;
foreach my $ref (sort keys %$pAnnot) {
	foreach my $name1 (sort keys %{$pAnnot->{$ref}}) {
		next if (keys %geneNames > 0 and not defined $geneNames{$name1});
		foreach my $name2 (sort keys %{$pAnnot->{$ref}}) {
			next if (keys %geneNames > 0 and not defined $geneNames{$name2});
			if ($name1 ne $name2 and not $seen{$name1}{$name2} and not $seen{$name2}{$name1}) {
				my $a1 = $pAnnot->{$ref}{$name1};
				my $a2 = $pAnnot->{$ref}{$name2};
				if (isOverlapping($a1, $a2)) 
				{
					print "$ref $name1 $name2 $a1->{start}:$a1->{end} $a2->{start}:$a2->{end}\n";
					$count++;
					$seen{$name1}{$name2}++;
					#last;
				}
			}
		}
	}	
}
print "Overlapping: $count\n";

exit;

#-------------------------------------------------------------------------------
sub loadGFF {
	my $filename = shift;
	my $pout;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	while(my $line = <INF> ) {
		chomp $line;
		my @tok = split /\t/,$line;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $frame  = $tok[7];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'gene');
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: discarding '$name' due to invalid coordinates (start=$start, end=$end)\n";
			next;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		$pout->{$ref}{$name} = { start => $start, end => $end };
	}
	close(INF);
	
	return $pout;
}

sub isOverlapping {
	my $a1 	= shift;
	my $a2 	= shift;
	return ($a1->{start} <= $a2->{end} and $a2->{start} <= $a1->{end});
}
