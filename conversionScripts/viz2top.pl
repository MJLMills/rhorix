#!/usr/bin/perl -w
# M J L Mills - Convert AIMAll .viz to QCT4Blender .top
# https://github.com/MJLMills/QCT4Blender

&readFile;
open(TOP,">","h2o\.top");
print TOP "\<topology\>\n";

for ($line=0; $line<@vizContents; $line++) {
  if ($vizContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+\=\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        
    $x = $2 * (10 ** $3);
    $y = $4 * (10 ** $5);
    $z = $6 * (10 ** $7);
        
    if ($vizContents[$line+1] =~ m/Type\s+\=\s+\((-?\d+)\,(-?\d+)\)/) {
      $rank = $1; $signature = $2;
    }

    print "FOUND CP: rank=$rank; signature=$signature\n";
    &printCP;

  } elsif ($vizContents[$line] =~ m/(\d+)\s+sample points along path from BCP/) {

    $nPoints = $1;
    my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
    print "FOUND AIL\: $nPoints POINTS\n";
    for ($ailLine=$line+1;$ailLine<$line+$nPoints+1;$ailLine++) {
      if ($vizContents[$ailLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+/) {
        $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
        $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
        $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
      } else {
        die "Malformed AIL point\n";
      }
    }
    #at this point, @ailPoints contains the points on the AIL and the object can be written to the .top file

  } elsif ($vizContents[$line] =~ m/(\d+)\s+sample points along IAS/) {
    
    $nPoints = $1;
    my @iasPoints_x; my @iasPoints_y; my @iasPoints_z;
    print "FOUND IAS\: $nPoints POINTS\n";
    for($iasLine=$line+1;$iasLine<$line+$nPoints;$iasLine++) {
      if ($vizContents[$iasLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+//) {
        $x = $1 * (10 ** $2); push(@iasPoints_x, $x);
        $y = $3 * (10 ** $4); push(@iasPoints_y, $y);
        $z = $5 * (10 ** $6); push(@iasPoints_z, $z);
      } else {
        die "Malformed IAS point\n";
      }
    }
    #at this point, @iasPoints contains the points on the IAS and the object can be written to the .top file
  }

}

print TOP "\<\/topology\>\n";
close TOP;

sub printIAS() {

  print TOP "  \<IAS\>\n";
  for ($point=0;$point<@iasPoints_x;$point++) {

  }
  print TOP "  \<\/IAS\>\n";

}

sub printAIL() {

  print TOP "  \<AIL\>\n";
  for ($point=0;$point<@ailPoints_x;$point++) {

  }
  print TOP "  \<\/AIL\>\n";

}

sub printCP() {

  print TOP "  \<CP\>\n";
  print TOP "    \<rank\>$rank\<\/rank\>\n";
  print TOP "    \<signature\>$signature\<\/signature\>\n";
  print TOP "    \<x\>$x\<\/x\>\n";
  print TOP "    \<y\>$y\<\/y\>\n";
  print TOP "    \<z\>$z\<\/z\>\n";
  print TOP "  \<\/CP\>\n";

}

sub readFile() {

  open(VIZ,"<","h2o\.sumviz") || die "SPECIFIED FILE NOT PRESENT\n";
  @vizContents = <VIZ>;
  close VIZ;
  chomp(@vizContents);

}
