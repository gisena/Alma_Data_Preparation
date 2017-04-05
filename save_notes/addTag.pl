#!/usr/local/bin/perl
#
# addTag.pl: add subfield 9LOCAL to a specific MARC field
#
# usage:	$BIN/addTag.pl <INPTAG> <OUTTAG> <OUTPUTFILE> <INPUTFILE>
#
$DEBUG=0;

use lib '/voyager/wrlcdb/local/lib';
require 'marc.pm';

# query parameters
$mfield = shift;
$lfield = shift;
$OUTFILE = shift;

print STDERR "\tSplitting files into $MAXRECORDS records each\n" if $DEBUG && $MAXRECORDS;

# MARC file record delimiter
$/ = chr(29);       # (0x1d)

$cnt = 0;
$non = 0;
open (OUT, "> $OUTFILE")
	|| die "can't open $OUTFILE\nscript aborted";
while (<>) {
	$cnt++;
	@marc = &marc2array($_);

	if (defined $MARC_HASH{$mfield}) {
		@newfields = ();
		foreach $i (split(/,/, $MARC_HASH{$mfield})) {
			print STDERR "in $i =>$marc[$i]<=\n" if $DEBUG;
			my $field = $lfield . substr($marc[$i],3) . '|9LOCAL'; 
 			print STDERR "in $field =>$marc[$i] # $lfield <=\n" if $DEBUG;
			if (grep {$_ eq $field} @marc) { # already preserved !
				$non++;
			} else {
				push(@newfields, $field);
			}
		}
		push(@marc,@newfields);
	} else {
		$non++;
	}
	
	$ldr = shift @marc;
        @NEWMARC = sort @marc;
        unshift @NEWMARC, $ldr;

	print OUT &array2marc(@NEWMARC);
}
close OUT;

print STDERR "$cnt MARC records processed\n";
print STDERR "$non records had no $mfield tag(s) to copy to $lfield tag(s).\n" if $non;
print STDERR "\noutput in $OUTFILE";
print STDERR ".\n";
