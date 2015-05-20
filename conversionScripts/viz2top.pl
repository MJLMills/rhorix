#!/usr/bin/perl -w
# M J L Mills - Convert AIMAll .sumviz to QCT4Blender .top
# https://github.com/MJLMills/QCT4Blender

@vizFiles = `ls *.*viz`; chomp(@vizFiles);
$nFiles = @vizFiles;
print "$nFiles VIZ FILES IN FOLDER\n";

open(TOP,">","reaction-A1\.top");
print TOP "\<topology\>\n";

for ($file=0;$file<@vizFiles;$file++) {

 print "READING $vizFiles[$file]\n";
  open(VIZ,"<","$vizFiles[$file]") || die "SPECIFIED FILE $vizFiles[$file] COULD NOT BE OPENED\n";
  @vizContents = <VIZ>;
  close VIZ;
  chomp(@vizContents);

  for ($line=0; $line<@vizContents; $line++) {
    if ($vizContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+\=\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        
      $x = $2 * (10 ** $3);
      $y = $4 * (10 ** $5);
      $z = $6 * (10 ** $7);
        
      if ($vizContents[$line+1] =~ m/Type\s+\=\s+\(([-+]?\d+)\,([-+]?\d+)\)\s+(\w+)\s+([a-zA-Z_]+\d+)/) {
        $rank = $1; $signature = $2; $type = $3; $label = $4;
      } else { die "Malformed CP located: $vizContents[$line+1]\n"; }

      if ($type eq "NACP") {
        $label =~ m/([a-zA-Z_]+)\d+/; $cpType = $1;
      } else { $cpType = lc("$type"); }

#      print "FOUND CP: rank=$rank; signature=$signature\n";
      printCP($cpType,$rank,$signature,$x,$y,$z);

    } elsif ($vizContents[$line] =~ m/(\d+)\s+sample points along/ && $vizContents[$line] !~ m/IAS|RCP/) {

      $nPoints = $1;
      my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
      print "FOUND LINE\: $nPoints POINTS\n";

      for ($ailLine=$line+1;$ailLine<$line+$nPoints+1;$ailLine++) {
        if ($vizContents[$ailLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)/) {
          $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
          $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
          $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
        } else {
          die "Malformed AIL point: $vizContents[$ailLine]\n";
        }
      }
      printLine(\@ailPoints_x,\@ailPoints_y,\@ailPoints_z);

    } elsif ($vizContents[$line] =~ m/\<IAS\s+Path\>/) {
    
      if ($vizContents[$line+1] =~ m/\s+\d+\s+(\d+)/) {

        $nPoints = $1;

        my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
        for ($iasLine=$line+2;$iasLine<$line+$nPoints+1;$iasLine++) {
          if ($vizContents[$iasLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)/) {
            $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
            $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
            $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
          } else {
            die "Malformed IAS Path point\:\t$vizContents[$iasLine]\n";
          }
        }
        printLine(\@ailPoints_x,\@ailPoints_y,\@ailPoints_z);

      } else {
        die "Malformed line in .iasviz file\n";
      }

    } elsif ($vizContents[$line] =~ m/\<Intersections of Integration Rays With IsoDensity Surfaces\>/) {

      if ($vizContents[$line+1] =~ m/\s+\d+\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+\s+-?\d+\.\d+E[-+]\d+\s+(\d+)/) {
        $nPoints = $1;
        print "FOUND RAY/SURF INTERSECTIONS - $nPoints POINTS\n";
        my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
        for ($iasLine=$line+2;$iasLine<$line+$nPoints+1;$iasLine++) {
          if ($vizContents[$iasLine] =~ m/\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)/) {
            $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
            $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
            $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
          } else {
            die "Malformed IAS Path point\:\t$vizContents[$iasLine]\n";
          }
        }
        printLine(\@ailPoints_x,\@ailPoints_y,\@ailPoints_z);

      } else {
        die "Malformed IAS Path point\:\t$vizContents[$iasLine]\n";
      }

    } elsif ($vizContents[$line] =~ m/\<Intersections of Integration Rays with Atomic Surface\>/) {

      if ($vizContents[$line+1] =~ m/\s+\d+\s+(\d+)\s+\d+/) {
        $nPoints = $1;
#        print "FOUND RAY/SURF INTERSECTIONS - $nPoints POINTS\n";
        my @ailPoints_x; my @ailPoints_y; my @ailPoints_z;
        for ($iasLine=$line+2;$iasLine<$line+$nPoints+1;$iasLine++) {
          if ($vizContents[$iasLine] =~ m/\s+\d+\s+\d+\s+\d+\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)\s+(-?\d+\.\d+)E([-+]\d+)/) {
            $x = $1 * (10 ** $2); push(@ailPoints_x, $x);
            $y = $3 * (10 ** $4); push(@ailPoints_y, $y);
            $z = $5 * (10 ** $6); push(@ailPoints_z, $z);
          } else {
            die "Malformed IAS Path point\:\t$vizContents[$iasLine]\n";
          }
        }
#        printLine(\@ailPoints_x,\@ailPoints_y,\@ailPoints_z);
      } else {
        die "Malformed line in .iasviz file\n";
      }      
    }
  }
} # end over files

print TOP "\<\/topology\>\n";
close TOP;

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

sub printCP {

  print TOP "  \<CP\>\n";
  print TOP "    \<type\>$cpType\<\/type\>\n";
  print TOP "    \<rank\>$rank\<\/rank\>\n";
  print TOP "    \<signature\>$signature\<\/signature\>\n";
  printf TOP "    \<x\>%8.5f\<\/x\>", $x;
  printf TOP "\<y\>%8.5f\<\/y\>", $y;
  printf TOP "\<z\>%8.5f\<\/z\>\n", $z;
  print TOP "  \<\/CP\>\n";

}

sub readFile() {

  open(VIZ,"<","h2.iasviz") || die "SPECIFIED FILE NOT PRESENT\n";
  @vizContents = <VIZ>;
  close VIZ;
  chomp(@vizContents);

}
