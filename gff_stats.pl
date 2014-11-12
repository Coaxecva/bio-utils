#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Info on types/counts for given GFF/GTF file.
# Author:	mdb
# Created:	9/20/10
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];
my @ANNOT_TYPES = ('gene', 'cds', 'exon');
my @CHROMOSOMES = ( 1..19, 'X', 'Y','MT' );
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_stats.pl <input_filename>\n" if ($#ARGV+1 < 1);

my ($pAnnot, $pTypes, $pRefs) = loadGFF($INPUT_FILE, \@ANNOT_TYPES, \@CHROMOSOMES);

# Display annotation counts per reference
print "Chromosomes:\n";
foreach my $ref (sort keys %$pRefs) {
	print "   $ref:\t$pRefs->{$ref}\n";
}

# Display annotations counts per type
print "Types:\n";
foreach my $type (sort keys %$pTypes) {
	print "   $type:\t$pTypes->{$type}\n";
}

# Display count of overlapping annotations
#my $count = 0;
#foreach my $type (keys %$pAnnot) {
#	foreach my $ref (keys %{$pAnnot->{$type}}) {
#		print "$ref\n";
#		foreach my $a1 (@{$pAnnot->{$type}{$ref}}) {
#			foreach my $a2 (@{$pAnnot->{$type}{$ref}}) {
#				if ($a1 != $a2) {
#					if (isOverlapping($a1, $a2) and $a1->{start} != $a2->{start} and $a1->{end} != $a2->{end}) {
#						#print "$ref $a1->{start}:$a1->{end} $a2->{start}:$a2->{end}\n";
#						$count++;
#						last;
#					}
#				}
#			}
#		}	
#	}	
#}
#print "Overlapping: $count\n";

exit;

#-------------------------------------------------------------------------------
sub loadGFF {
	my $filename = shift;
	my $pTypes = shift;			# optional
	my $pChromosomes = shift;	# optional
	my $pout;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my %type_filter;
	%type_filter = map { lc($_) => 1 } @$pTypes if (defined $pTypes and @$pTypes > 0);
	my %ref_filter;
	%ref_filter = map {$_ => 1 } @$pChromosomes if (defined $pChromosomes and @$pChromosomes > 0);
	
	my $count = 0;
	my %names;
	my %types;
	my %refs;
	my $maxLen = 0;
	
	my $line;
	my @tok;
	while( $line = <INF> ) {
		chomp $line;
		@tok = split /\t/,$line;
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
		
		push @{ $pout->{$type}{$ref} }, 
				{ name => $name, start => $start, end => $end, 
					attr => $attr, strand => $strand, frame => $frame };
					
		my $len = $end - $start + 1;
		$maxLen = $len if ($len > $maxLen);
					
		$types{$type}++;
		$refs{$ref}++;
		$count++;
	}
	close(INF);
	
	print "$count annotations loaded, max length $maxLen\n";

	return ($pout, \%types, \%refs);
}

sub isOverlapping {
	my $a1 	= shift;
	my $a2 	= shift;
	
	return ($a1->{start} <= $a2->{end} and $a2->{start} <= $a1->{end});
}
