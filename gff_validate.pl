#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:  Check transcript annotations for mixed strands and frame shifts.
# Author:	mdb
# Created:	3/17/11
#------------------------------------------------------------------------------
my $INPUT_FILE = '/data/genome/mus/ensembl61/combined.gtf';
my @ANNOT_TYPES = ('cds');
my @CHROMOSOMES = ( 1..19, 'X', 'Y','MT' );
my $GENE_NAME = $ARGV[0]; # optional, for testing
#-------------------------------------------------------------------------------

use warnings;
use strict;
use List::Util qw(first);

my ($pGenes, $pTrans) = loadGFF($INPUT_FILE, \@ANNOT_TYPES, \@CHROMOSOMES);

my $multiStrand = 0;
foreach my $name (sort keys %$pGenes) {
	next if (defined $GENE_NAME and $name ne $GENE_NAME);
	
	my %strands;
	foreach my $cds (@{$pGenes->{$name}}) {
		$strands{$cds->{strand}}++;
	}
	if (keys %strands > 1) {
		$multiStrand++;
		print "$name\n";
	}
}

print "Total genes: " . (keys %$pGenes) . "\n";
print "Multiple strands: $multiStrand\n\n";

my $total = 0;
my $badFrame = 0;
foreach my $name (sort keys %$pTrans) {
	next if (defined $GENE_NAME and $name !~ /$GENE_NAME/);
	print "$name\n" if (defined $GENE_NAME);	
	
	$total++;
	my $firstCDS = first { defined($_) } @{$pTrans->{$name}};
	my @a = $firstCDS->{strand} eq '+' ? 
				sort {$a->{start} <=> $b->{start}} @{$pTrans->{$name}} :
				sort {$b->{start} <=> $a->{start}} @{$pTrans->{$name}}; # reverse order for negative strand
	my $inFrame = checkFrames(\@a);
	if (not $inFrame) {
		$badFrame++;
		print "$name\n";
	}
}

print "Total transcripts: $total\n";
print "Bad frames: $badFrame\n";

exit;

#-------------------------------------------------------------------------------
sub checkFrames {
	my $pin = shift;
	
	my $inFrame = 1;
	
	for (my $i = 0;  $i < @$pin - 1;  $i++) {
		my $r1 = $pin->[$i];
		my $r2 = $pin->[$i+1];
		
		my $len1 = $r1->{end} - $r1->{start} + 1;
		if ((((($len1 - $r1->{frame}) % 3) + $r2->{frame}) % 3) != 0) {
			#print "$r1->{start}:$r1->{end},$r1->{frame} $r2->{start}:$r2->{end},$r2->{frame}\n";
			$inFrame = 0;
			last;
		}
	}
	
	return $inFrame;	
}
#-------------------------------------------------------------------------------
sub loadGFF {
	my $filename = shift;
	my $pTypes = shift;			# optional
	my $pChromosomes = shift;	# optional
	my ($pout, $pout2);

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my %type_filter;
	%type_filter = map { lc($_) => 1 } @$pTypes if (defined $pTypes and @$pTypes > 0);
	my %ref_filter;
	%ref_filter = map {$_ => 1 } @$pChromosomes if (defined $pChromosomes and @$pChromosomes > 0);
	
	my $count = 0;
	my %names;
	my $maxLen = 0;
	
	my @tok;
	while (<INF>) {
		chomp;
		@tok = split /\t/;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $frame  = $tok[7];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if (keys %type_filter > 0 and not defined $type_filter{$type});
		
		# Parse name from attributes field
		my $name;
		if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
	 		$name = $1;
		}
		
		if ($type eq 'gene') {
			if (defined $names{$name}) {
				print "Warning: duplicate gene name '$name'\n";
			}
			$names{$name} = 1;
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
		next if (keys %ref_filter > 0 and not defined $ref_filter{$ref});
		
		#my %new = ( start => $start, end => $end, strand => $strand, frame => $frame );
		push @{ $pout->{$name}}, { start => $start, end => $end, strand => $strand, frame => $frame }; #\%new;
		my ($transName) = $attr =~ /transcript_name \"(\S+)\";/;
		push @{ $pout2->{$transName}}, { start => $start, end => $end, strand => $strand, frame => $frame }; #\%new;
					
		my $len = $end - $start + 1;
		$maxLen = $len if ($len > $maxLen);
					
		$count++;
	}
	close(INF);
	
	print "$count annotations loaded, max length $maxLen\n";

	return ($pout, $pout2);
}
