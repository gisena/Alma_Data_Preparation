#!/usr/local/bin/perl
# getTag.pl
# retrieve bibids of bib records that contain tag for a given libid
# usage: $BIN/getTag.pl <tag> <libid> 
#

# import the MARC perl library
use Getopt::Long;
use lib '/voyager/wrlcdb/local/lib';
require 'marcUTF.pm';

$tag=@ARGV[0]; 
$lib=@ARGV[1];

# db connection parameters
$ENV{'ORACLE_HOME'}="/prod/orahome";
$DBNAME= 'WRLCDB';

open (SIDFILE, "/voyager/wrlcdb/local/lib/dbsid");
$SID = <SIDFILE>; chomp $SID;
close SIDFILE;

open (UPWFILE, "/voyager/wrlcdb/local/lib/dbupw");
$DBPASSW = <UPWFILE>; chomp $DBPASSW;
close UPWFILE;

open (UNMFILE, "/voyager/wrlcdb/local/lib/dbunm");
$DBUSER = <UNMFILE>; chomp $DBUSER;
close UNMFILE;

#$rptpath = "/home/voyager/tmp/${lib}_$tag.txt";
#if (open(REPORT, ">$rptpath")) {
#        $rpth = *REPORT;
#} else {
#        print STDERR "Warning: can't open $rptpath, using STDOUT\n\n";
#        $rpth = *STDOUT;
#}

#print $rpth "";

#
# begin and end dates
#
# latest request:
$rptdate = `date +"%b %d, %Y"`;
$tmpdate = `date +"%b%d%Y"`;

#
# SQL statement to select bibs suppressed from CUA
#
$SQL = "select bib_id
	  from $DBNAME.bib_master
	 where LIBRARY_ID in 
	(select LIBRARY_ID from library  where substr(LIBRARY_NAME,1,2) = '$lib')
         and suppress_in_opac='N' ";

#
# Get bibids  w/ $tag fields
#
use DBI;
use Benchmark;

$t0 = new Benchmark;
$dbh = DBI->connect('dbi:Oracle:', "$DBUSER\@$SID", $DBPASSW)
	|| die "ERROR:connect: $DBI::errstr\n";
$bibh = $dbh->prepare($SQL)
	|| die "ERROR:prepare: $DBI::err: $DBI::errstr\n";
$rc = $bibh->execute
	|| die "ERROR:execute: $DBI::err: $DBI::errstr\n";

while(($bibid) = $bibh->fetchrow_array) {
	$total++;

		# select the blob data that makes up the MARC record for this bib
		$SQL = "select record_segment from $DBNAME.bib_data
			 where bib_id = $bibid order by seqnum";
		$dath = $dbh->prepare($SQL)
			|| die "ERROR:prepare: $DBI::err: $DBI::errstr\n";
		$rc = $dath->execute
			|| die "ERROR:execute: $DBI::err: $DBI::errstr\n";
		$blob = '';
		while( ($data) = $dath->fetchrow_array) {
			$blob .= $data;
		}
		$dath->finish;

		if ($blob ne '') {
			$TOTAL += 1;
			# parse the MARC BLOB
			@marc = &marc2array($blob);
		        if (defined $MARC_HASH{$tag}) {	
			#	print $rpth "$bibid\n";
				print "$bibid\n";
			}
			$blob = '';
		}
### just a counter  to let you know it's churning
###		$dot++;
###		if ($dot == 1000) {
###			print STDERR '.';
###			$dot = 0;
###		}
}
###print STDERR "\n";
$t1 = new Benchmark;

$bibh->finish; $dbh->disconnect;
