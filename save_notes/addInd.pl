#!/usr/local/bin/perl
#
# addInd.pl: change indicator in marc field.
#            This must always be called after marc field changes.
#             
# usage:     $BIN/addInd.pl <INPTAG> <OUTIND> <INPFILE> > <OUTFILE>
#               <INPTAG> - source MARC field 
#               <OUTIND> - new indicator for <INPTAG>
#               <INPFILE> - source marc-format file
#     

$DEBUG=1;

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
			my $field = substr($marc[$i],0,4) . $lfield . substr($marc[$i],6);
			$marc[$i] = $field;
			print STDERR "in new $i =>$marc[$i]<=\n" if $DEBUG;
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
print STDERR "$non records with no $mfield tag(s) for updating indicators to $lfield.\n" if $non  && $DEBUG;
