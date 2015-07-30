#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Compare two GFF/GTF files
# Author:	mdb
# Created:	7/30/15
#------------------------------------------------------------------------------
my $INPUT_FILE1 = shift;
my $INPUT_FILE2 = shift;
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Hash::Diff qw(diff);
use Data::Dumper;

die "Usage:  gff_compare.pl <file1> <file2>\n" unless ($INPUT_FILE1 && $INPUT_FILE2);

my $p1 = loadGFF($INPUT_FILE1);
my $p2 = loadGFF($INPUT_FILE2);

my $common = 0;
my $changed = 0;
my $notFoundIn1 = 0;
my $notFoundIn2 = 0;

foreach my $type (keys %$p1) {
	foreach my $ref (keys %{$p1->{$type}}) {
		foreach my $start (keys %{$p1->{$type}{$ref}}) {
		    foreach my $end (keys %{$p1->{$type}{$ref}{$start}}) {
    			if (defined $p2->{$type}{$ref}{$start}{$end}) {
    				$common++;
    				
    				my $a1 = $p1->{$type}{$ref}{$start}{$end};
    				my $a2 = $p2->{$type}{$ref}{$start}{$end};
    				
    				my $diff = diff($a1, $a2);
    				
    				if ($a1->{strand} ne $a2->{strand} or
    					keys %$diff)
    				{
    					$changed++;
    					print "!! $type $ref:$start:$end\n";
    					#print Dumper $diff, "\n";
    				}
    			}
    			else {
    				$notFoundIn2++;
    				print "unique to first: $type $ref:$start:$end\n";
    			}
		    }
		}
	}	
}

foreach my $type (keys %$p2) {
	foreach my $ref (keys %{$p2->{$type}}) {
		foreach my $start (keys %{$p2->{$type}{$ref}}) {
		    foreach my $end (keys %{$p2->{$type}{$ref}{$start}}) {
    			if (not defined $p1->{$type}{$ref}{$start}{$end}) {
    				$notFoundIn1++;	
    				print "unique to second: $type $ref:$start:$end\n";
    			}
		    }
		}
	}	
}

print "Common: $common\n";
print "Different: $changed\n";
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
		next if ($line =~ /^#/);
		@tok = split /\t/,$line;
		my $ref    = $tok[0];
		my $type   = lc($tok[2]);
		my $start  = $tok[3];
		my $end    = $tok[4];
		my $strand = $tok[6];
		my $attr   = $tok[8];
		
		die "Error: invalid format\n" if (@tok < 9);
		
		# Validate coordinates
		if ($start > $end) {
			print "Warning: invalid coordinates (start=$start, end=$end)\n";
		}
		
		# Parse attributes field
		my %attr;
		foreach (split(';', $attr)) {
		    my ($key, $val) = split('=', $_);
		    $attr{$key} = $val;
		}
		
		$pout->{$type}{$ref}{$start}{$end} =
			{ start => $start, end => $end, strand => $strand, attr => \%attr };
				
		$count++;
	}
	close(INF);
	
	print "$filename: $count annotations\n";

	return $pout;
}

