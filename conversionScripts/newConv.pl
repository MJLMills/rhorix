#!/usr/bin/perl -w
# Matthew J L Mills
# Convert AIMAll output to .top format.

my $fileName = &checkArgs(@ARGV);
my @fileContents = &readFile($fileName);
openTopology($fileName);

my $currentCP;
for ($i=0; $i<@fileContents; $i++) {

  $line = "$fileContents[$i]";

  if ($line =~ m/CP\#\s+(\d+)\s+Coords\s+\=/) {
    $currentCP = $1;
    &parseCP(@fileContents[$i .. $i+1]) 
  } elsif ($line =~ m/(\d+)\s+sample points along(.*)path/) { 
    &parseLine(@fileContents[$i .. $i+$1]) 
  }

}

&closeTopology;

#!#! SUBROUTINES

sub openTopology {
  $_[0] =~ m/(.*)\..*/;
  open(TOP,">","$1\.top") || die "Cannot create \.top file\: $1\.top\n";
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
      $x = $1; $y = $2; $z = $3; #$rho = $4;
      push(@xCoords,$x); push(@yCoords,$y); push(@zCoords,$z);
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

  open(SVZ,"<","$_[0]") || die "Cannot open file\: $_[0]\n";
  my @sumvizContents = <SVZ>;
  chomp(@sumvizContents);
  close SVZ;
  return @sumvizContents;

}

sub checkArgs {

  my $nArg = @_;
  if ($nArg == 0 || $nArg > 1) {
    die "Incorrect number of arguments\: $nArg\nPlease run script as \"perl newConv.pl filename.sumviz\"\n";
  } else {
    return "$_[0]";
  }

}
