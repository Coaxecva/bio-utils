#!/usr/bin/env perl
#-------------------------------------------------------------------------------
# Purpose:	Report stats on specified pileup file.
# Author:	mdb
# Created:	1/27/11
#------------------------------------------------------------------------------
my $INPUT_FILE = $ARGV[0];	# input pileup filename
#------------------------------------------------------------------------------
my $MIN_DEPTH = 6;			# minimum HQ read depth
my $MIN_BASE_QUAL = 20;		# definition of HQ (High Quality)
   $MIN_BASE_QUAL += 33;	# scale for FASTQ encoding
#-------------------------------------------------------------------------------

use warnings;
use strict;

die "Usage:  pileup_test.pl <pileup>\n" if (@ARGV < 1);

use Inline C => <<'END_C';

FILE* pileup_open(char* filename) {
	return fopen(filename,"r");
}

void pileup_close(FILE* f) {
	fclose(f);
}

int pileup_ready(FILE* f) {
	return !feof(f);
}

int pileup_get(FILE* f, int min_depth, int min_base_qual) {
    while (!feof(f)) {
    	int pos, depth;
    	char line[10000];
    	char chr[80];
    	char refbase[80];
    	char seq[10000];
    	char qual[10000];

		fgets(line, 10000, f);
		if (line == NULL || strlen(line) < 1) {
			break;	
		}
		//printf(line);
        //sscanf(line, "%s\t%i\t%s\t%i\t%s\t%s", chr, &pos, refbase, &depth, seq, qual);
        //printf("%s\t%i\t%s\t%i\t%s\t%s\n", chr, pos, refbase, depth, seq, qual);
        
        //if (depth >= min_depth) {
        	//depth = c_countHQBases(seq, qual, min_base_qual);
        	//if (depth >= min_depth) {
        		//Inline_Stack_Vars;
				//Inline_Stack_Reset;
				//Inline_Stack_Push(sv_2mortal(newSVpv(chr, strlen(chr))));
				//Inline_Stack_Push(sv_2mortal(newSViv(pos)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(refbase, strlen(refbase))));
				//Inline_Stack_Push(sv_2mortal(newSViv(depth)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(seq, strlen(seq))));
				//Inline_Stack_Push(sv_2mortal(newSVpv(qual, strlen(qual))));
				//Inline_Stack_Done;
				//return;
        	//}
		//}
	}
	printf("all done!");
	return;
}

int pileup_test(char* filename, int min_depth, int min_base_qual, 
	SV* out_chr, SV* out_pos, SV* out_refbase, SV* out_depth, SV* out_seq, SV* out_qual) 
{
	FILE* f;
	//Inline_Stack_Vars;
	
	f = fopen(filename,"r");
    while (!feof(f)) {
    	int pos, depth;
    	char line[10000];
    	char chr[80];
    	char refbase[80];
    	char seq[10000];
    	char qual[10000];

		fgets(line, 10000, f);
		//if (line == NULL || strlen(line) < 1) {
		//	break;	
		//}
		//printf(line);
		sscanf(line, "%s\t%i\t%s\t%i\t%s\t%s", chr, &pos, refbase, &depth, seq, qual);
        //fscanf(f, "%s\t%i\t%s\t%i\t%s\t%s", chr, &pos, refbase, &depth, seq, qual);
        printf("%s\t%i\t%s\t%i\t%s\t%s\n", chr, pos, refbase, depth, seq, qual);
        
        if (depth >= min_depth) {
        	depth = c_countHQBases(seq, qual, min_base_qual);
        	if (depth >= min_depth) {
        		fclose(f);
				
				//Inline_Stack_Reset;
				//Inline_Stack_Push(sv_2mortal(newSVpv(chr, strlen(chr))));
				//Inline_Stack_Push(sv_2mortal(newSViv(pos)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(refbase, strlen(refbase))));
				//Inline_Stack_Push(sv_2mortal(newSViv(depth)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(seq, strlen(seq))));
				//Inline_Stack_Push(sv_2mortal(newSVpv(qual, strlen(qual))));
				//Inline_Stack_Done;
				
				sv_setpv(out_chr, chr);
				sv_setiv(out_pos, pos);
				sv_setpv(out_refbase, refbase);
				sv_setiv(out_depth, depth);
				sv_setpv(out_seq, seq);
				sv_setpv(out_qual, qual);
				
				return;
        	}
		}
	}
	printf("all done!");
	fclose(f);
	return;
}

void stacktest(char* str) {
	int pos = 1234;
	Inline_Stack_Vars;
	Inline_Stack_Reset;
	Inline_Stack_Push(sv_2mortal(newSVpv(str, strlen(str))));
	Inline_Stack_Push(sv_2mortal(newSViv(pos)));
	Inline_Stack_Done;
}

void pileup_test2(char* filename, int min_depth, int min_base_qual) 
{
	FILE* f;
	
	f = fopen(filename,"r");
    while (!feof(f)) {
    	int pos, depth;
    	char line[10000];
    	char chr[80];
    	char refbase[80];
    	char seq[10000];
    	char qual[10000];

		fgets(line, 10000, f);
		sscanf(line, "%s\t%i\t%s\t%i\t%s\t%s", chr, &pos, refbase, &depth, seq, qual);
        printf("%s\t%i\t%s\t%i\t%s\t%s\n", chr, pos, refbase, depth, seq, qual);
        
        if (depth >= min_depth) {
        	depth = c_countHQBases(seq, qual, min_base_qual);
        	if (depth >= min_depth) {
        		dSP;

         		ENTER;
         		SAVETMPS;

				XPUSHs(sv_2mortal(newSVpv(chr, strlen(chr))));
				XPUSHs(sv_2mortal(newSViv(pos)));
				XPUSHs(sv_2mortal(newSVpv(refbase, strlen(refbase))));
				XPUSHs(sv_2mortal(newSViv(depth)));
				XPUSHs(sv_2mortal(newSVpv(seq, strlen(seq))));
				XPUSHs(sv_2mortal(newSVpv(qual, strlen(qual))));
				
        		//XPUSHs(sv_2mortal(newSVpvf("%s\t%i\t%s\t%i\t%s\t%s\n", chr, pos, refbase, depth, seq, qual)));
        		PUTBACK;
        		
        		call_pv("callback", G_DISCARD);
        		
        		FREETMPS;
        		LEAVE;
        		
        		//Inline_Stack_Vars;
        		
        		fclose(f);
				
				//Inline_Stack_Reset;
				//Inline_Stack_Push(sv_2mortal(newSVpv(chr, strlen(chr))));
				//Inline_Stack_Push(sv_2mortal(newSViv(pos)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(refbase, strlen(refbase))));
				//Inline_Stack_Push(sv_2mortal(newSViv(depth)));
				//Inline_Stack_Push(sv_2mortal(newSVpv(seq, strlen(seq))));
				//Inline_Stack_Push(sv_2mortal(newSVpv(qual, strlen(qual))));
				//Inline_Stack_Done;

				return;
        	}
		}
	}
	fclose(f);
	return;
}

int c_countHQBases(char* seq, char* qual, int min_base_qual) {
	int count = 0;
	int i, j;
	int slen = strlen(seq);
	int qlen = strlen(qual);
	
	for (i = 0, j = 0;  i < slen;  i++) {
		if (i >= slen) {
			printf("error 5: %i/%i %i/%i %s %s\n", i, slen, j, qlen, seq, qual);	
		}
		
		char c = seq[i];
		if (c == '>' || c == '<') {
			j++;
			continue;
		}
		else if (c == '$') {
			continue;
		}
		else if (c == '^') {
			i++;
			continue;
		}
		else if (c == '+' || c == '-') {
			c = seq[i+1];
			if (c >= '0' && c <= '9') {
				c -= '0';
				i++;
				char c2 = seq[i+1];
				if (c2 >= '0' && c2 <= '9') {
					c2 -= '0';
					int n = c*10 + c2;
					i += n + 1;
				}
				else {
					i += c;
				}
			}
			continue;
		}

		if (j >= qlen) {
			printf("error 4: %i/%i %i/%i %s %s\n", i, slen, j, qlen, seq, qual);	
		}		
		char q = qual[j++];
		if (q >= min_base_qual) {
			count++;
		}
	}
	if (i != slen || j != qlen) {
		printf("error 3: %i/%i %i/%i %s %s\n", i, slen, j, qlen, seq, qual);
	}
	
	return count;
}
END_C

#print stacktest("test");

#my ($chr, $pos, $refbase, $depth, $seq, $qual);
#pileup_test($INPUT_FILE, $MIN_DEPTH, $MIN_BASE_QUAL, $chr, $pos, $refbase, $depth, $seq, $qual);
#print map {"$_ "} pileup_test2($INPUT_FILE, $MIN_DEPTH, $MIN_BASE_QUAL);

pileup_test2($INPUT_FILE, $MIN_DEPTH, $MIN_BASE_QUAL);
#my ($chr, $pos, $refbase, $depth, $seq, $qual) = pileup_test2($INPUT_FILE, $MIN_DEPTH, $MIN_BASE_QUAL);
#print "$chr $pos $refbase $depth $seq $qual\n";

#print "$chr $pos $refbase $depth $seq $qual\n";
#my $fh = pileup_open($INPUT_FILE);
#while (pileup_ready($fh)) {
#	#my ($chr, $pos, $refbase, $depth, $seq, $qual) = pileup_get($fh, $MIN_DEPTH, $MIN_BASE_QUAL);
#	#print "$chr\t$pos\t$refbase\t$depth\t$seq\t$qual\n";
#	#my ($pos, $depth) = pileup_get($fh, $MIN_DEPTH, $MIN_BASE_QUAL);
#	pileup_get($fh, $MIN_DEPTH, $MIN_BASE_QUAL);
#	#print "$pos\n";
#}
#pileup_close($fh);
exit;

#-------------------------------------------------------------------------------
sub callback {
	print map "$_\n", @_;
	
	my (undef, undef, undef, $chr, $pos, $refbase, $hqDepth, $seq, $qual) = @_;
	print "$chr, $pos, $refbase, $hqDepth, $seq, $qual\n";
}

sub countHQBases {
	my $pseq = shift;
	my $pqual = shift;
	
	my $count = 0;
	my $totalQual = 0;
	
	my ($i, $j);
	for (($i, $j) = (0, 0);  $i < length($$pseq);  $i++) {
		my $c = substr($$pseq, $i, 1); # Using substr is tiny bit faster than split
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
			$totalQual += $q;
		}
	}
	die "error 3: $i $j $$pseq $$pqual" if ($i != length $$pseq or $j != length $$pqual);
	
	my $avg = 0;
	$avg = $totalQual/$count if ($count > 0);
	return ($count, $avg);
}
