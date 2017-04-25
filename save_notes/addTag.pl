#!/usr/local/bin/perl
#
# addTag.pl: copy contents of MARC field <INPTAG> into a new MARC field <OUTTAG> and add subfield 9LOCAL
#
# usage:	$BIN/addTag.pl <INPTAG> <OUTTAG> <INPFILE> >  <OUTFILE>
#               <INPTAG> - source MARC field to be copied
#               <OUTTAG> - New target MARC field copied from <INPTAG> with added subfield 9LOCAL
#               <INPFILE) - source MARC format file
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

	print &array2marc(@NEWMARC);
}
close OUT;

print STDERR "$cnt MARC records processed\n"  if $DEBUG;
print STDERR "$non records had no $mfield tag(s) to copy to $lfield tag(s).\n" if $non  && $DEBUG;
