#!/usr/local/bin/perl
#
# moveTag.pl: rename tag and add subfield 9LOCAL to a specific MARC field
#
# usage:	$BIN/moveTag.pl <INPTAG> <OUTTAG> <INPFILE> > <OUTFILE>
#               <INPTAG> - source MARC field 
#               <OUTTAG> - renamed MARC field with subfield 9LOCAL added
#               <INPFILE> - source marc-format file
#

$DEBUG=0;

use lib '/voyager/wrlcdb/local/lib';
require 'marc.pm';

# query parameters
$mfield = shift;
$lfield = shift;


# MARC file record delimiter
$/ = chr(29);       # (0x1d)

$cnt = 0;
$non = 0;

while (<>) {
	$cnt++;
	@marc = &marc2array($_);

	if (defined $MARC_HASH{$mfield}) {
		@newfields = ();
		@oldfields = ();
		foreach $i (split(/,/, $MARC_HASH{$mfield})) {
			print STDERR "in $i =>$marc[$i]<=\n" if $DEBUG;
			my $field = $lfield . substr($marc[$i],3) . '|9LOCAL';
			$marc[$i] = $field;
			print STDERR "in i:$i => marci: $marc[$i] should be same !!!! repl:$field\n" if $DEBUG; 
		}
	} else {
		$non++;
	}
	
	$ldr = shift @marc;
        @NEWMARC = sort @marc;
        unshift @NEWMARC, $ldr;

	print &array2marc(@NEWMARC);
}

print STDERR "$cnt MARC records processed\n"  if $DEBUG;
print STDERR "$non records had no $mfield tag(s) to move to $lfield tag(s).\n" if $non  && $DEBUG;
