#!/usr/local/bin/perl
#
# addSubfield.pl: add subfield 9LOCAL to a specific MARC field
#
# usage:	 $BIN/addSubfield.pl  <INPTAG> <OUTPUTFILE> <INPUTFILE>
#
$DEBUG=0;

use lib '/voyager/wrlcdb/local/lib';
require 'marc.pm';

# query parameters
$mfield = shift;
#$OUTDIR  = shift;
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
		foreach $i (split(/,/, $MARC_HASH{$mfield})) {
			print STDERR "in $i =>$marc[$i]<=\n" if $DEBUG;
			my $field = substr($marc[$i],7);		# strip field tag
			$field =~ s/^\s+//; $field =~ s/\s+$//;		# trim spaces
		        $localStr='|9LOCAL';	
			if (index($field, $localStr) < 0) {
				@subfields = split(/\|/, $field);		# split subfields
                                substr($marc[$i],7) .= '|9LOCAL';
			        print STDERR "out $i =>$marc[$i]<=\n" if $DEBUG;
                        }
			else { # already preserved
		                $non++;
        		}
		}
	} else {
		$non++;
	}

	print OUT &array2marc(@marc);
}
close OUT;


print STDERR "$cnt MARC records processed\n";
print STDERR "$non records had no $mfield tags to update.\n" if $non;
print STDERR "\noutput in $OUTFILE";
print STDERR ".\n";
