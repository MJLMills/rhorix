#!/usr/bin/perl -w
# Matthew J L Mills
# Convert AIMAll output to .top format.

my $fileName = &checkArgs(@ARGV);
my @fileContents = &readFile($fileName);
openTopology($fileName);

$fileName =~ m/(.*)\.(.*)/;
$name = $1; $extension = $2;
$atomFolder = "$name\_atomicfiles";

if ($extension eq "sumviz" || $extension eq "mgpviz") {
  &parseSUMVIZ(@fileContents);
  &parseAssociatedIASVIZ($atomFolder);
} elsif ($extension eq "iasviz") {
  &parseIASVIZ(@fileContents);
} else {
  die "Extension \'$extension\' not recognised\n";
}

&closeTopology;

sub parseAssociatedIASVIZ {
  if (-d "$_[0]") {
    print "Located atomic files\n";
    @iasvizFiles = `ls $atomFolder\/*.iasviz`;
    $nFiles = @iasvizFiles; print "Found $nFiles atomic output files\n";
    #parse each iasviz file located
    foreach (@iasvizFiles) {
      my @iasvizContents = &readFile("$atomFolder\/$_");
      &parseIASVIZsurfaces(@iasvizContents);
    }
  }
}

#!#! SUBROUTINES

#just get the IAS from the iasviz file - use when mgpviz/sumviz is present
sub parseIASVIZsurfaces {

  for ($i=0; $i<@_; $i++) {

    $line = "$_[$i]";

    if ($line =~ m/\<IAS Path\>/) {
      if ($_[$i+1] =~ m/\d+\s+(\d+)/) {
        &parseIASVIZline(@_[$i+2 .. $i+$1+1]);
      } else { 
        die "Malformed line in IASVIZ\n"; 
      }
    }
  }

}

sub parseIASVIZ {

  my $currentCP;
  for ($i=0; $i<@_; $i++) {

    $line = "$_[$i]";

    if ($line =~ m/\<IAS Path\>/ || $line =~ m/\<Bond Path\>/) {
      #IAS Paths are GPs from a BCP out to an isovalue. Not connected.
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

  local @xCoords; local @yCoords; local @zCoords;

  for (@_) {
    if ($_ =~ m/(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
      push(@xCoords,$1); push(@yCoords,$2); push(@zCoords,$3);
    } else { die "Malformed line\n"; }
  }

  &printSurface(\@xCoords,\@yCoords,\@zCoords);

}

sub parseIASIntersections {

  local @xCoords; local @yCoords; local @zCoords;

  for (@_) {
    if ($_ =~ m/\d+\s+\d+\s+\d+\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+/) {
      push(@xCoords,$1); push(@yCoords,$2); push(@zCoords,$3);
    }
  }

  &printSurface(\@xCoords,\@yCoords,\@zCoords);

}

#Parses sumviz and mgpviz files and prints topological objects
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

#Parse a gradient path appearing in an IASVIZ file
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

#Parse a GP from a sum/mgpviz file
sub parseLine {

  local @xCoords; local @yCoords; local @zCoords;

  if ($_[0] =~ m/\d+\s+sample points along(.*)path(.*)/) { 
    $A = $1; $B = $2;
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

#Print a GP to the top file
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

#Parse a CP from a sum/mgpviz file
sub parseCP {

  if ($_[0] =~ m/Coords\s+\=\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
    $x = $1; $y = $2; $z = $3;
  } else { die "Malformed CP line\: $_[0]\n"; }

  if ($_[1] =~ m/Type\s+\=\s+\((\d+)\,([-+]\d+)\)\s+(\w+)\s+(.*)/) {
    $rank = $1; $signature = $2; $type = $3; $conn = $4;
    if ($type eq "NACP") {
      $conn =~ m/([a-zA-Z])\d+/;
      $type = $1;
    } else {
      $type = lc($type);
    }
    #print "CONNECTIVITY\: $4\n";
  } elsif ($_[1] =~ m/Type\s+\=\s+\((\d+)\,([-+]\d+)\)\s+(\w+)/) {
    $rank = $1; $signature = $2; $type = $3;
    $type = lc($type);
  } else { 
    die "Malformed CP line\: $_[1]\n"; 
  }

  &printCP($x,$y,$z,$rank,$signature,$type);
  
}

#Print a CP object to the .top file
sub printCP {

  print  TOP "  \<CP\>\n";
  printf TOP "    \<type\>%s\<\/type\>\n", $_[5];
  printf TOP "    \<rank\>%1d\<\/rank\>\n", $_[3];
  printf TOP "    \<signature\>%1d\<\/signature\>\n", $_[4];
  printf TOP "    \<x\>%8.5f\<\/x\> \<y\>%8.5f\<\/y\> \<z\>%8.5f\<\/z\>\n", $_[0], $_[1], $_[2];
  print  TOP "  \<\/CP\>\n";

}

#Attempt to read a file (arg is filename)
sub readFile {

  open(INP,"<","$_[0]") || die "Cannot open input file\: $_[0] for reading\n";
  my @inpContents = <INP>;
  chomp(@inpContents);
  close INP;
  return @inpContents;

}

#Check that 1 arg was passed (the filename)
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

#Print a disconnected surface to the .top file
sub printSurface {

  #sub must receive five lists as references (i.e. \@array1, \@array2, \@array3)
  local ($xPoints, $yPoints, $zPoints) = @_;
  local $nPoints = scalar(@$xPoints);

  print TOP "  \<SURFACE\>\n";
  print TOP "    \<A\>H2\<\/A\>\n";
  for (local $point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }

  print TOP "  \<\/SURFACE\>\n";

}
