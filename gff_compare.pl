#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Compare two GFF/GTF files
# Author:	mdb
# Created:	2/3/11
#------------------------------------------------------------------------------
my $INPUT_FILE1 = $ARGV[0];
my $INPUT_FILE2 = $ARGV[1];
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  gff_compare.pl <file1> <file2>\n" if ($#ARGV+1 < 2);

my $p1 = loadGFF($INPUT_FILE1);
my $p2 = loadGFF($INPUT_FILE2);

my $common = 0;
my $changed = 0;
my $notFoundIn1 = 0;
my $notFoundIn2 = 0;

foreach my $type (keys %$p1) {
	foreach my $ref (keys %{$p1->{$type}}) {
		foreach my $name (keys %{$p1->{$type}{$ref}}) {
			if (defined $p2->{$type}{$ref}{$name}) {
				$common++;
				
				my $a1 = $p1->{$type}{$ref}{$name};
				my $a2 = $p2->{$type}{$ref}{$name};
				if ($a1->{start}  != $a2->{start} or 
					$a1->{end}    != $a2->{end}   or 
					$a1->{strand} ne $a2->{strand})
				{
					$changed++;
					print "$type $name $a1->{start}:$a1->{end} $a1->{strand}\n";
					print "$type $name $a2->{start}:$a2->{end} $a2->{strand}\n";
				}
			}
			else {
				$notFoundIn2++;
				#print "unique to first: $name\n";
			}
		}
	}	
}

foreach my $type (keys %$p1) {
	foreach my $ref (keys %{$p2->{$type}}) {
		foreach my $name (keys %{$p2->{$type}{$ref}}) {
			if (not defined $p1->{$type}{$ref}{$name}) {
				$notFoundIn1++;	
				#print "unique to second: $name\n";
			}
		}
	}	
}

print "Common: $common\n";
print "Changed: $changed\n";
print "Unique to first: $notFoundIn2\n";
print "Unique to second: $notFoundIn1\n";

sub loadGFF {
	my $filename = shift;
	my $pout;

	open(INF, $filename) or 
		die("Error: cannot open file '$filename'\n");
	
	my $count = 0;
	
	my $line;
	my @tok;
	while ($line = <INF>) {
		chomp $line;
		@tok = split /\t/,$line;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $attr   = $tok[8];
		
		die "Error: invalid line in file\n" if (@tok < 9);
		
		next if ($type ne 'gene' and $type ne 'cds');
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: invalid coordinates (start=$start, end=$end)\n";
		}
		
		# Parse name from attributes field
		my $name;
		if ($type eq 'gene') {
			if ($attr =~ /Name=(\S+);/ or $attr =~ /gene_name \"(\S+)\"/) {
		 		$name = $1;
			}
		}
		elsif ($type eq 'cds') {
			($name) = $attr =~ /transcript_name \"(\S+)\";/;
			my ($exon) = $attr =~ /exon_number \"(\S+)\";/;
			$name .= '_' . $exon;
		}
		
		# Extract chromosome number from reference name
		if ($ref =~ /chr(\w+)/) {
			$ref = $1;
		}
		
		$pout->{$type}{$ref}{$name} =
			{ name => $name, start => $start, end => $end, 
					attr => $attr, strand => $strand };
				
		$count++;
	}
	close(INF);
	
	print "$filename: $count annotations\n";

	return $pout;
}

