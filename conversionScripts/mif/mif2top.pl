open(MIF,"<","compound1\.mif");
@mifContents = <MIF>;
close MIF;
chomp(@mifContents);

open(TOP,">","new\.top");
print TOP "\<topology\>\n";

for ($line=0;$line<@mifContents;$line++) {
  
  if ($mifContents[$line] =~ m/AIL\s+/) {
    #take care of duplicate lines in mif
    if ($mifContents[$line+1] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

      my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;
      for ($ailLine=$line+1;$ailLine<@mifContents;$ailLine++) {
        if ($mifContents[$ailLine] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
          push(@ailCoords_x,$1); push(@ailCoords_y,$2); push(@ailCoords_z,$3);
        } else {
          last;
        }
      }
      printLine(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z);

    }

  } elsif ($mifContents[$line+1] =~ m/CRIT/) {

    for ($cpLine=$line+1;$cpLine<@mifContents;$cpLine++) {
      if ($mifContents[$cpLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        $cpType = $1; $x = $2; $y = $3; $z = $4;

        if ($cpType ~= m/bcp/) {
            $rank = 3; $signature = -1;
        } elsif ($cpType ~= m/rcp/) {
            $rank = 3; $signature = 1;
        } elsif ($cpType ~= m/ccp/) {
            $rank = 3; $signature = 3;
        } else {
            $rank = 3; $signature = -3;
        }

        printCP();

      } else {
        last;
      }
    }
  }
}

print TOP "\<\/topology\>\n";
close TOP;

sub printLine {

  #sub must receive three lists as references (i.e. \@array1, \@array2, \@array3)
  my ($xPoints, $yPoints, $zPoints) = @_;
  $nPoints = scalar(@$xPoints);
  print "writing $nPoints points\n";

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

