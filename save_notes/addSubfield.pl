#!/usr/local/bin/perl
#
# addSubfield.pl: add subfield  to a specific MARC field
#
# usage:	 $BIN/addSubfield.pl <INPTAG> <INPSUBF> <INPFILE> > <OUTFILE>
#		 e.g.:  $BIN/addSubfield.pl 500 '|9LOCAL' input.mrc > output.mrc
#                <INPTAG> - source tag to get subfield <INPSUBF>
#                <INPSUBF> - subfield to be added
#                <INPFILE> - source marc-format file
#   
$DEBUG=0;

use lib '/voyager/wrlcdb/local/lib';
require 'marc.pm';

# query parameters
$mfield = shift;
$mtext = shift;

# MARC file record delimiter
$/ = chr(29);       # (0x1d)

$cnt = 0;
$non = 0;

while (<>) {
	$cnt++;
	@marc = &marc2array($_);

	if (defined $MARC_HASH{$mfield}) {
		foreach $i (split(/,/, $MARC_HASH{$mfield})) {
			print STDERR "in $i =>$marc[$i]<=\n" if $DEBUG;
			my $field = substr($marc[$i],7);		# strip field tag
			$field =~ s/^\s+//; $field =~ s/\s+$//;		# trim spaces
			if (index($field, $mtext) < 0) {
				@subfields = split(/\|/, $field);	# split subfields
                                substr($marc[$i],7) .= $mtext;          # e.g. $mtext='|9LOCAL'
			        print STDERR "out $i =>$marc[$i]<=\n" if $DEBUG;
                        }
			else { # already preserved
		                $non++;
        		}
		}
	} else {
		$non++;
	}
	print &array2marc(@marc);
}

print STDERR "$cnt MARC records processed\n" if $DEBUG;
print STDERR "$non records had no $mfield tags to update.\n" if $non && $DEBUG;
