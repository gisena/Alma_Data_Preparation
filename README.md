# Alma_Data_Preparation

1. addSubfield.pl: add subfield  to a specific MARC field
 usage:   $BIN/addSubfield.pl <INPTAG> <INPSUBF> <INPFILE> > <OUTFILE>
          <INPTAG> - source tag to get subfield <INPSUBF>
          <INPSUBF> - subfield to be added
          <INPFILE> - source marc-format file
 sample:  $BIN/addSubfield.pl 500 '|9LOCAL' input.mrc > output.mrc
	  add subfield '|9LOCAL' to each 500 marc field


2. addTag.pl: copy contents of MARC field <INPTAG> into a new MARC field <OUTTAG> and add subfield 9LOCAL
 usage:  $BIN/addTag.pl <INPTAG> <OUTTAG> <INPFILE> >  <OUTFILE>
         <INPTAG> - source MARC field to be copied
         <OUTTAG> - New target MARC field copied from <INPTAG> with added subfield 9LOCAL
         <INPFILE) - source MARC format file
 sample:  $BIN/addTag.pl 500 590 input.mrc > output.mrc
          create new field 590 for each field 500 found.
          copy contents of each 500 field into the corresponding new 590 and add subfield '9LOCAL'

3. getTag.pl : retrieve bibids of all bib records that contain tag for a given libid
 usage: $BIN/getTag.pl <INPTAG> <LIBNAME> > <list of bib_ids with INPTAG>
        <INPTAG> - input tag constraint
        <LIBNAME> - 2 letter name of library bibids to search for
 sample: $BIN/getTag.pl 500 'CU' > cu_bibids.txt
         get all bibids of bib records that have 500 field

4. moveTag.pl: rename tag and add subfield 9LOCAL to a specific MARC field
 usage: $BIN/moveTag.pl <INPTAG> <OUTTAG> <INPFILE> > <OUTFILE>
        <INPTAG> - source MARC field
        <OUTTAG> - renamed MARC field with subfield 9LOCAL added
        <INPFILE> - source marc-format file
 sample: $BIN/moveTag.pl 500 590 input.mrc > output.mrc
         move all 500 fields to 590 fields and add subfield '|9LOCAL' to each one.

5. taghold.pl: address unicode errors
               need marc to text and text to marc to do clean-up:
 sample: $BIN/taghold.pl --ifmt=marc --ofmt=text input.mrc >  input.txt
         $BIN/taghold.pl --ifmt=text --ofmt=marc input.txt > output.mrc

6. testTag.sh  - sample using the above scripts.
