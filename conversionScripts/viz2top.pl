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
    printCP();

  } elsif ($vizContents[$line] =~ m/(\d+)\s+sample points along/) {

    $nPoints = $1;
    my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
    print "FOUND LINE\: $nPoints POINTS\n";
    for ($ailLine=$line+1;$ailLine<$line+$nPoints+1;$ailLine++) {
      if ($vizContents[$ailLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+/) {
        $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
        $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
        $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
      } else {
        die "Malformed AIL point\n";
      }
    }
    printLine(\@ailPoints_x,\@ailPoints_y,\@ailPoints_z);
  } 

}

print TOP "\<\/topology\>\n";
close TOP;

sub printLine {

  #sub must receive three lists as references (i.e. \@array1, \@array2, \@array3)
  my ($xPoints, $yPoints, $zPoints) = @_;
  $nPoints = scalar(@$xPoints);

  print TOP "  \<LINE\>\n";
  for ($point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }
  print TOP "  \<\/LINE\>\n";

}

sub printCP {

  print TOP "  \<CP\>\n";
  print TOP "    \<rank\>$rank\<\/rank\>\n";
  print TOP "    \<signature\>$signature\<\/signature\>\n";
  printf TOP "    \<x\>%8.5f\<\/x\>", $x;
  printf TOP "\<y\>%8.5f\<\/y\>", $y;
  printf TOP "\<z\>%8.5f\<\/z\>\n", $z;
  print TOP "  \<\/CP\>\n";

}

sub readFile() {

  open(VIZ,"<","h2o\.sumviz") || die "SPECIFIED FILE NOT PRESENT\n";
  @vizContents = <VIZ>;
  close VIZ;
  chomp(@vizContents);

}
