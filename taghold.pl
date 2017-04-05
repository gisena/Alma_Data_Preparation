#!/usr/local/bin/perl 
# ggs 2012.12.14 WR-11913 address unicode errors make modified marcUTF.pm
#
use Getopt::Long;

use lib '/voyager/wrlcdb/local/lib';
require 'marcUTF.pm';

# format for text output
# (N.B. write command deletes trailing spaces, so ... this is not used)
format =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$field
~~    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$field
.

%options = (    ifmt => 'marc',
                ofmt => 'marc');
&GetOptions(\%options, 'ifmt=s', 'ofmt=s', 'skip=i', 'copy=i', 'match=s',
                'g=s', "help");

if ($options{'help'}) {
    print "Usage: taghold.pl [ --ifmt=[text|marc] ] [ --ofmt=[text|marc] ]\n";
    print "               [ [--skip=n] [--copy=n] | [--match='string'] ]\n";
    print "               [ --g=globalfile ]\n";
    print "               [filename | -]\n";
    print "\n";
    exit;
}

# default pattern for leader
$ldrdef = "LDR 00000mam  2200000 a 4500";


#cnts
$cntin = 0;
$cntout = 0;

# set up globals (if any) for text-to-marc conversion

@globals = ();
if ($options{'g'} and $options{'ifmt'} eq 'text') {

    # globals array contains fields to be added to all records
    # (only applies to text-to-marc conversion)
    $globals = $options{'g'};
    open GLOBALS, $globals or die "Cannot find $globals";
    while (<GLOBALS>) {
        chop;
        if ( /^LDR/ ) { # leader codes
          $ldrdef = $_;
        } else { # new tag
          push(@globals,$_);
        }
    }
}

# set the input record separator
if ($options{'ifmt'} eq 'text') {
    $/ = "\n\n";
} else {
    $/ = chr(29);       # (0x1d)
}

CASE: {
    if (defined $options{'copy'}) {
        if (defined $options{'skip'}) {
            for ($i=0; $i < $options{'skip'}; $i++) {
                $_ = <>;
                last CASE if eof();
            }
        }

        for ($i=0; $i < $options{'copy'}; $i++) {
            $_ = <>;
            &outputter($_);
            last CASE if eof();
        }
        last CASE;
    }

    if (defined $options{'match'}) {

        # convert the query string into a suitable form
        $query = $options{'match'};
        $query =~ tr/A-Z/a-z/;
        $query =~ s/\W/ /g;
        $query =~ s/\s+/ /g;

        LINE: while (<>) {
            if (/$query/ois) {
                &outputter($_);
            }
        }
        last CASE;
    }

    while (<>) { # default case -- copy everything
        &outputter($_);
    }

    #new
    if ($options{'ifmt'} eq 'marc' and $options{'ofmt'} eq 'text') { 
      print STDERR "$cntin records input; ";
    }
    if ($options{'ifmt'} eq 'text' and $options{'ofmt'} eq 'marc') { 
      print STDERR "$cntout records output.\n";
    }
    #new
}

exit;

sub outputter {
    if ($options{'ifmt'} eq 'marc' and $options{'ofmt'} eq 'text') {
        &marc2text($_);
        return;
    }

    if ($options{'ifmt'} eq 'text' and $options{'ofmt'} eq 'marc') {
        chop($_);
        &text2marc($_);
        return;
    }

    # in and out have the same format -- so just print the record

        print $_;
}

sub marc2text {
    $cntin = $cntin + 1;
    my @marc = &marc2array($_);

    foreach $field ( @marc ) {

        print "$field\n";
        #write;                 # NB write removes trailing blanks
    }

    $searchkey = 'nokey';
    print "\n";

}

sub text2marc {

    $cntout = $cntout + 1;

    #initialise stuff
    my @trec = @globals;
    my $ldr = $ldrdef;

    foreach (split "\n", $_) {

        if (/^LDR /) {
            $ldr = $_;
            next;
        }


        # remove trailing whitespace
        #s/\s+$//;

        # continuation line (assumes lines broken at word boundaries)
        if (s/^\s+/ /) {
            $trec[$#trec] .= $_;
            next;
        }

        # new tag, same record
        push(@trec,$_);
    }
    print &array2marc($ldr, sort @trec);
}

#new

#trim leading and trailing spaces
sub mytrim {
  my ($tmp) = @_;
  $_ = $tmp;
  s/^\s*(.*?)\s*$/$1/;
  $tmp = $_;
  return $tmp;
}

#split on one or more spaces
sub mysplit {
  my ($tmp) = @_;
  ($tmpkey) = split(/\s+/, $tmp);
  return $tmpkey;
}

#split on the subfield delimiter
sub mysplitsub {
  my ($tmp) = @_;
  ($tmpkey) = split(/\|/, $tmp);
  return $tmpkey;
}

#encode reserved and unsafe URL characters
sub myencode {
  my ($tmp) = @_;
  $_ = $tmp;

  s/%/%25/g;      #Percent                %       %25  must be encoded first
  s/;/%3B/g;      #Semicolon              ;       %3B
  s/\//%2F/g;     #Slash                  /       %2F  need \
  s/\?/%3F/g;     #Question mark          ?       %3F  need \
  s/:/%3A/g;      #Colon                  :       %3A
  s/@/%40/g;      #At sign                @       %40
  s/=/%3D/g;      #Equal sign             =       %3D
  s/&/%26/g;      #Ampersand              &       %26
  s/</%3C/g;      #Less than sign         <       %3C
  s/>/%3E/g;      #Greater than sign      >       %3E
  s/\(/%28/g;     #Open parenthesis       (       %28
  s/\)/%29/g;     #Close parenthesis      )       %29
  s/"/%22/g;      #Double quotation mark  "       %22
  s/#/%23/g;      #Hash symbol            #       %23
  s/{/%7B/g;      #Left curly brace       {       %7B
  s/}/%7D/g;      #Right curly brace      }       %7D
  s/\|/%7C/g;     #Vertical bar           |       %7C  need \
  s/\\/%5C/g;     #Backslash              \       %5C  need \ 
  s/\^/%5E/g;     #Caret                  ^       %5E  need \
  s/~/%7E/g;      #Tilde                  ~       %7E
  s/\[/%5B/g;     #Left square bracket    [       %5B  need \
  s/\]/%5D/g;     #Right square bracket   ]       %5D  need \
  s/`/%60/g;      #Back single quotation  `       %60
  s/\s/%20/g;     #Space                          %20  need \

  $tmp = $_;
  return $tmp;
}

#new

#End.

