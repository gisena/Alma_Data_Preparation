#!/bin/ksh
#
# getTag.sh
# Description: Find bibds that contain tags to be modified
#	Combine and get unique bibids to be used to export the bib records to be modified
#      usage:  run from root's cron:
#              30 08 * * 0  /m1/voyager/wrlcdb/local/bin/getTag.sh
#
# addSubfield.pl:#usage: $BIN/addSubfield.pl  <INPTAG> <INPFILE> > <OUTFILE>
# addTag.pl:#     usage: $BIN/addTag.pl <INPTAG> <OUTTAG> <INPFILE> >  <OUTFILE>
# getTag.pl:#     usage: $BIN/getTag.pl <INPTAG> <LIBNAME> > <list of bib_ids with INPTAG>
# moveTag.pl:#    usage: $BIN/moveTag.pl <INPTAG> <OUTTAG> <INPFILE> > <OUTFILE>
#
#

# set oracle environment:
export ORACLE_SID=VGER
export ORACLE_HOME=/prod/orahome
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

MM=`date +%m`
YY=`date +%y`
DD=`date +%d`
if [[($MM -eq 0)]]; then
   ((MM = 12))
fi
typeset -RZ2 MM

# export information
LIBNAME="CU"
BIBDIR=/home/voyager/tmp
BIBIDS=${BIBDIR}/${LIBNAME}_tags_$DD$MM$YY
BIBMARC=${BIBIDS}.mrc

# set environment
LOG=/tmp/tag_${LIBNAME}.log
TMPLOG=/tmp/tag_${LIBNAME}.tlog
DIR=/m1/voyager/wrlcdb
BIN=$DIR/local/bin
. $DIR/ini/voyager.env                                          >  $LOG 2>&1

# import information
export REPORTSDIR=$VOYAGER/$DATABASE/rpt
BULK="$DIR/sbin/Pbulkimport -K ADDKEY -C -M -oWRLC"
PROFILE="CU001"

MAILTO="sena@wrlc.org"
IMPLOG=sena@wrlc.org

echo "Begin $LIBNAME tag preservation on `date`"		>> $LOG 2>&1
echo "===================="					>> $LOG 2>&1

echo ""								>> $LOG 2>&1
echo "STARTED bibid retrieval for $LIBNAME with tags to be modified  on `date`..." >> $LOG 2>&1
$BIN/getTag.pl 500 $LIBNAME > $BIBIDS
$BIN/getTag.pl 590 $LIBNAME >> $BIBIDS   
echo "ENDED bibid retrieval for $LIBNAME with tags to be modified  on `date`..." >> $LOG 2>&1

cat $BIBIDS | sort -u | head -700 > ${BIBIDS}.bibid

echo ""									>> $LOG 2>&1
echo "................................................."		>> $LOG 2>&1
echo "Unique Bibid retrieval  ended `date`"                             >> $LOG 2>&1
echo ""									>> $LOG 2>&1

CNTBIB=`cat  ${BIBIDS}.bibid | wc -l | tr -d " "`
echo "$CNTBIB bib ids found!"          >> $LOG 2>&1

if [ $CNTBIB -ne "0" ]
   then
     echo ""          >> $LOG 2>&1
     echo "Exporting $LIBNAME bib records with local tags to be preserved  ..."  >> $LOG 2>&1
     echo ""                                   >> $LOG 2>&1

     split -l 300000  -a 1 ${BIBIDS}.bibid ${BIBIDS}.
     cntr=0
     for iBIBIDS in `ls ${BIBIDS}.a*`
     do
	$DIR/sbin/Pmarcexport -rB -mM -t$iBIBIDS -o${BIBMARC}.${cntr} >> $LOG 2>&1
        echo "_________________________________________________________">> $LOG 2>&1
        echo ""                                                 >> $LOG 2>&1

	SUFF=`date +%Y%m%d`
	IMPORTFIL=${BIBMARC}.${cntr}.impt

	$BIN/addSubfield.pl 590 ${BIBMARC}.${cntr} >  ${BIBMARC}_addsubf.${cntr} 2>> $LOG
	$BIN/addTag.pl 500 590 ${BIBMARC}_addsubf.${cntr} > ${BIBMARC}_590.${cntr} 2>> $LOG

	$BIN/taghold.pl --ifmt=marc --ofmt=text ${BIBMARC}_590.${cntr} >  ${BIBMARC}.${cntr}.cp 2>> $LOG
	$BIN/taghold.pl --ifmt=text --ofmt=marc ${BIBMARC}.${cntr}.cp >  $IMPORTFIL 2>> $LOG 
	
	sleep 10
	$BULK -f$IMPORTFIL -i$PROFILE      >> $LOG 2>&1

        echo ""                          >> $LOG 2>&1
        PID=`tail -2 $LOG | head -1 | cut -d" " -f4`
        sleep 4
        if [ $? -ne 0 ]
        then
                echo "ERROR: Problem importing $LIBNAME records"     >> $LOG 2>&1
                /bin/mail -s "ERROR: Problem importing $LIBNAME records" "$IMPLOG" < $LOG
                        exit 1
        fi
        if [ -f $REPORTSDIR/log.imp.$SUFF.$PID ]
        then
                echo ""                                         >> $LOG 2>&1
                echo "Bulk Import Results:"                     >> $LOG 2>&1
                echo "--------------------"                     >> $LOG 2>&1
                /prod/ldstat.pl $REPORTSDIR/log.imp.$SUFF.$PID  >> $LOG 2>&1
                /bin/mail -s "$LIBNAME bulkimport Log" "$IMPLOG" < $REPORTSDIR/log.imp.$SUFF.$PID
        else
                echo "$IMPORTFIL MARC Import to Voyager"        > $TMPLOG 2>&1
                echo "Warning: can't find log $REPORTSDIR/log.imp.$SUFF.$PID">>$TMPLOG 2>&1
                echo "bulkimport was run, but my timestamp is incorrect">>$TMPLOG 2>&1
                echo "log will have to be downloaded from server"       >> $TMPLOG 2>&1
                tail -3 $TMPLOG                                         >> $LOG 2>&1
        fi

        echo "................................................." >> $LOG 2>&1
        echo "bulk import ended `date`"                          >> $LOG 2>&1
        echo ""                                                  >> $LOG 2>&1
        sleep 60


        cntr=`expr $cntr + 1`
	
     done

fi

echo "===================="                                     >> $LOG 2>&1
echo "End $LIBNAME tag preservation `date`..."                  >> $LOG 2>&1

/bin/mail -s "$LIBNAME Tag preservation log" "$MAILTO" < $LOG
