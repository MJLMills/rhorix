#!/usr/bin/perl -w
# Matthew J L Mills
# Convert AIMAll output to .top format.

my $fileName = &checkArgs(@ARGV);
my @fileContents = &readFile($fileName);
openTopology($fileName);

$fileName =~ m/.*\.(.*)/;
$extension = $1;

if ($extension eq "sumviz") {
  &parseSUMVIZ(@fileContents);
} elsif ($extension eq "iasviz") {
  &parseIASVIZ(@fileContents);
}

&closeTopology;

#!#! SUBROUTINES

sub parseIASVIZ {

  my $currentCP;
  for ($i=0; $i<@_; $i++) {

    $line = "$_[$i]";

    if ($line =~ m/\<IAS Path\>/ || $line =~ m/\<Bond Path\>/) {

      if ($_[$i+1] =~ m/\d+\s+(\d+)/) {
        &parseIASVIZline(@_[$i+2 .. $i+$1+1]); 
      } else { die "Malformed line in IASVIZ\n"; }

    } elsif ($line =~ m/\<Intersections of Integration Rays with Atomic Surface\>/) {

      if ($_[$i+1] =~ m/\d+\s+(\d+)/) {
        &parseIASIntersections(@_[$i+2 .. $i+$1+1]);
        #There are an additional $1 single numbers after a line with 2 ints after the intersections - dunno what they are.
        #  5.8509422438E-04
      } else { die "Malformed line in IASVIZ\n"; }

    } elsif ($line =~ m/<Intersections of Integration Rays With IsoDensity Surfaces>/) {
      if ($_[$i+1] =~ m/(\d+)\s+(\d+\.\d+E[-+]\d+)\s+(\d+\.\d+E[-+]\d+)\s+(\d+\.\d+E[-+]\d+)\s+(\d+)/) {
        #what are the sci-notation numbers? $5 is the number of points to read
        &parseIsoDensityIntersections(@_[$i+2 .. $i+1+$5]);
      } else { die "Malformed line in IASVIZ\n"; }      
    } elsif ($line =~ m/\<Electron Density Critical Points in Atomic Surface\>/) {
      if ($_[$i+1] =~ m/(\d+)/) {
        &parseIASCriticalPoints(@_[$i+2 .. $i+1+$1]);        
      } else { die "Malformed line in IASVIZ\n"; }
    }

  }

}

sub parseIASCriticalPoints {
  foreach (@_) {
    if ($_ =~ m/(\w+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+-?\d+\.\d+E[-+]\d+/) {
      $type = $1;
      $rank = &typeToRank($type);
      $signature = &typeToSignature($type);
      &printCP($2,$3,$4,$rank,$signature,$type);
    }
  }
}

sub parseIsoDensityIntersections {
  for (@_) {
    if ($_ =~ m/(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
      $x = $1; $y = $2; $z = $3;
      #figure out what to do with these
    } else { die "Malformed line\n"; }
  }
}

sub parseIASIntersections {
#regex must match: x y z rho ? ? ? ?
#     1     0     1  9.9959105336E-01   1.6994685093E-02   2.2997972220E-02   8.4400576730E-01  -1.0000000000E+00   1.3000000000E+01  -1.0000000000E+00   1.3000000000E+01
}

sub parseSUMVIZ {

  my $currentCP;
  for ($i=0; $i<@_; $i++) {

    $line = "$_[$i]";

    if ($line =~ m/CP\#\s+(\d+)\s+Coords\s+\=/) {
      $currentCP = $1;
      &parseCP(@_[$i .. $i+1]);
    } elsif ($line =~ m/(\d+)\s+sample points along(.*)path/) {
      &parseLine(@_[$i .. $i+$1]);
    }

  }

}

sub parseIASVIZline {

  local @xCoords; local @yCoords; local @zCoords;

  foreach (@_) {
    if ($_ =~ m/(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+-?\d+\.\d+E[+-]\d+/) {
      push(@xCoords,$1); push(@yCoords,$2); push(@zCoords,$3);
    } else {
      die "Malformed LINE\: $_\n";
    }
  }

  &printLine(\@xCoords,\@yCoords,\@zCoords);

}


sub openTopology {
  $_[0] =~ m/(.*)\..*/;
  open(TOP,">","$1\.top") || die "Cannot create \.top file\: $1\.top for output\n";
  print TOP "\<topology\>\n";
}

sub closeTopology {
  print TOP "\<\/topology\>\n";
  close TOP;
}

sub parseLine {

  local @xCoords; local @yCoords; local @zCoords;

  if ($_[0] =~ m/\d+\s+sample points along(.*)path(.*)/) { 
    $A = $1; $B = $2;
#    print "$A\t$B\n";
    if ($A =~ m/IAS/) {
      $lineType = "$A";
    } elsif ($B =~ m/from BCP to atom\s+(.*)/) {
      $lineType = "AIL"
    } elsif ($B =~ m/from RCP to BCP between atoms\s+(.*)\s+and\s+(.*)/) {
      $lineType = "RCP-BCP"
    } elsif ($A =~ /RCP attractor/) {
      $lineType = "RCP-attractor"
    } else {
      die "Unknown Line Type\: sample points along $A path $B\n";
    }
  } else { die "Malformed LINE\n" }

  for ($p=1; $p<@_; $p++) {
    if ($_[$p] =~ m/(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+-?\d+\.\d+E[+-]\d+/) {
      #$rho = $4;
      push(@xCoords,$1); push(@yCoords,$2); push(@zCoords,$3);
    } else { die "Malformed GP line\: $_[$p]\n";}
  }
#  print "Parsed line of type\: $lineType\n";
  &printLine(\@xCoords,\@yCoords,\@zCoords);

}

sub printLine {

  #sub must receive three lists as references (i.e. \@array1, \@array2, \@array3)
  local ($xPoints, $yPoints, $zPoints) = @_;
  local $nPoints = scalar(@$xPoints);

  print TOP "  \<LINE\>\n";
  print TOP "    \<A\>1\<\/A\>\n";
  print TOP "    \<B\>1\<\/B\>\n";

  for (local $point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }
  print TOP "  \<\/LINE\>\n";

}

sub parseCP {

  if ($_[0] =~ m/Coords\s+\=\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
    $x = $1; $y = $2; $z = $3;
  } else { die "Malformed CP line\: $_[0]\n"; }

  if ($_[1] =~ m/Type\s+\=\s+\((\d+)\,([-+]\d+)\)\s+(\w+)\s+(.*)/) {
    $rank = $1; $signature = $2; $type = $3;
    #print "CONNECTIVITY\: $4\n";
  } else { die "Malformed CP line\: $_[1]\n"; }

  &printCP($x,$y,$z,$rank,$signature,$type);
  
}

sub printCP {

  print  TOP "  \<CP\>\n";
  printf TOP "    \<type\>%s\<\/type\>\n", $_[5];
  printf TOP "    \<rank\>%1d\<\/rank\>\n", $_[3];
  printf TOP "    \<signature\>%1d\<\/signature\>\n", $_[4];
  printf TOP "    \<x\>%8.5f\<\/x\> \<y\>%8.5f\<\/y\> \<z\>%8.5f\<\/z\>\n", $_[0], $_[1], $_[2];
  print  TOP "  \<\/CP\>\n";

}

sub readFile {

  open(INP,"<","$_[0]") || die "Cannot open input file\: $_[0] for reading\n";
  my @inpContents = <INP>;
  chomp(@inpContents);
  close INP;
  return @inpContents;

}

sub checkArgs {

  my $nArg = @_;
  if ($nArg == 0 || $nArg > 1) {
    die "Incorrect number of arguments\: $nArg\nPlease run script as \"perl newConv.pl filename\"\n";
  } else {
    return "$_[0]";
  }

}

sub typeToRank {

  $arg = lc($_[0]);

  if ($arg eq "bcp" || $arg eq "rcp" || $arg eq "ccp") {
    return 3;
  }

}

sub typeToSignature {

  $arg = lc($_[0]);

  if ($arg eq "bcp") {
    return -1;
  } elsif ($arg eq "rcp") {
    return +1
  } elsif ($arg eq "ccp") {
    return -3
  } elsif ($arg eq "nacp") {
    return +3;
  }

}
