#!/usr/bin/env perl
#
# Prints statistics for the given FASTA file.  
#
# Matt 5/31/07
# -----------------------------------------------------------------------------

use warnings;
use strict;
use POSIX; # for LONG_MAX

die "Usage:  fasta_stats.pl [-s] <input_filename> [section_name]\n" if ($#ARGV+1 < 1);

my $OPTIONS;
if ($ARGV[0] eq '-s') {
	$OPTIONS = '-s'; # -s for summary only
	shift @ARGV;
}
my $INF = shift @ARGV; # input file name
my $SECTION_NAME = shift @ARGV; # optional section name

my $ALL_STATS = 0;

my $line;
my $secName;
my $numSections = 0;
my $totalSize = 0; # all bases (incl. N's)
my $totalNs = 0;
my $totalACGT = 0;
my $totalAmbiguous = 0;
my $totalGC = 0;
my $totalRepeats = 0;
my $totalInvalid = 0;
my $acgt = 0;
my $n = 0;
my $ambiguous = 0;
my $gc = 0;
my $repeats = 0;
my $invalid = 0;

my $secSize = 0;
my $numLines = 0;
my ($minSecSize,$maxSecSize) = (LONG_MAX,0);
my ($minCount,$maxCount);

my $parsex = qr/^\>(\S+)/;

open INF,"<$INF" or die "Can't open file: $INF\n";
while ($line = <INF>) {
    chomp $line;
    
    if ($line =~ $parsex) { # Start of new section
    	next if (defined $SECTION_NAME and $1 ne $SECTION_NAME);
		finishSection() if (defined $secName and $secName ne '');
		
        # Reset loop
        $secName = $1;
        $secSize = 0;
        $n = 0;
        $acgt = 0;
        $ambiguous = 0;
        $gc = 0;
        $repeats = 0;
        $invalid = 0;
        $numSections++;
    }
    else { # Sequence data
        $secSize += () = $line =~ /\S/g;
        if ($ALL_STATS) {
            $n += () = $line =~ /N/gi;
            $ambiguous += () = $line =~ /[BDHKMRSWVXY]/gi;
            $acgt += () = $line =~ /[ACGT]/gi;
            $gc += () = $line =~ /[GC]/gi;
            $invalid += () = $line =~ /[^ACGTBDHKMRSWVXYN]/gi;
            #$repeats += countRepeats(\$line);
        }
    }
    $numLines++;
}
close INF;

# Do last section
finishSection();

# Print totals
print "\nNum sections:  $numSections\n",
      "Num lines:     $numLines\n",
      "Total size:    $totalSize\n";
if ($ALL_STATS) {
    print "               $totalACGT ACGT's, " . ($totalSize-$totalNs) . " non-N's, $n N's, $totalAmbiguous ambiguous, $totalInvalid invalid)\n";
    print "Avg GC%:       " . (100*$totalGC/$totalSize) . "\n";
    #print "% Repeats:     " . (100*$totalRepeats/$totalSize) . "\n";
    print "Min sec size:  $minSecSize ($minCount)\n",
          "Max sec size:  $maxSecSize ($maxCount)\n",
          "Avg sec size:  " . ($totalSize/$numSections) . "\n";
}

exit;

#-------------------------------------------------------------------------------
sub finishSection {
    $totalSize += $secSize;
    if ($ALL_STATS) {
    	$totalNs += $n;
    	$totalACGT += $acgt;
    	$totalAmbiguous += $ambiguous;
    	$totalGC += $gc;
    	$totalRepeats += $repeats;
    	$totalInvalid += $invalid;
        if ($secSize < $minSecSize) { $minSecSize = $secSize; $minCount = 1; }
        elsif ($secSize == $minSecSize) { $minCount++; }
        if ($secSize > $maxSecSize) { $maxSecSize = $secSize; $maxCount = 1; }
        elsif ($secSize == $maxSecSize) { $maxCount++; }
    	print "$secName\n\t$secSize bases\t$acgt ACGT's\t" . ($secSize-$n) . " non-N's\t$n N's\t$ambiguous ambiguous\t$invalid invalid\n" if (not $OPTIONS or $OPTIONS !~ /-s/);
    }
    else {
        print "$secName\t$secSize bases\n" if (not $OPTIONS or $OPTIONS !~ /-s/);
    }
}

sub countRepeats {
	my $p = shift;
	
	my $count = 0;
	my $c;
	my @a = split(//, $$p);
	foreach my $c2 (@a) {
		$count++ if (defined $c and $c2 eq $c and $c2 ne 'N');
		$c = $c2;
	}
	
	return $count;
}