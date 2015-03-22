open(MIF,"<","ALANINE0000\.mif");
@mifContents = <MIF>;
close MIF;
chomp(@mifContents);

open(TOP,">","new\.top");
print TOP "\<topology\>\n";

for ($line=0;$line<@mifContents;$line++) {
  
  if ($mifContents[$line] =~ m/AIL\s+\d+\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/) {

    $atomA = "$1$2"; 
    $atomB = "$3$4";
    #take care of duplicate lines in mif
    if ($mifContents[$line+1] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
   
      my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;
      for ($ailLine=$line+1;$ailLine<@mifContents;$ailLine++) {
        if ($mifContents[$ailLine] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
          push(@ailCoords_x,$1); push(@ailCoords_y,$2); push(@ailCoords_z,$3);
        } else {
          $line = $ailLine - 1;
          last;
        }
      }
      printLine(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z);

    }

  } elsif ($mifContents[$line] =~ m/CRIT/) {

    for ($cpLine=$line+1;$cpLine<@mifContents;$cpLine++) {
      if ($mifContents[$cpLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        $cpType = $1; $x = $2; $y = $3; $z = $4;

        if ($cpType =~ m/bcp/) {
            $rank = 3; $signature = -1;
        } elsif ($cpType =~ m/rcp/) {
            $rank = 3; $signature = 1;
        } elsif ($cpType =~ m/ccp/) {
            $rank = 3; $signature = 3;
        } else {
            $rank = 3; $signature = -3;
        }

        printCP();

      } else {
        $line = $cpLine - 1;
        last;
      }
    }
  } elsif ($mifContents[$line] =~ m/atom\s+(\w+)\_(\d+)/ || $mifContents[$line] =~ m/surf\s+(\w+)\_(\d+)/) {

    $atom = "$1$2";
    $pointID = 0;
    #write the surface out - mifs are not in a consistent format so all possibilities are needed
    #ORDER IS SUPER IMPORTANT!!!
    my @edgeA; my @edgeB;
    my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;

    for ($surfLine=$line+2;$surfLine<@mifContents;$surfLine++) {
      if ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        # 1 1 1
        $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5 * (10 ** $6); 
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        # 0 0 1
        $x = $1; $y = $2; $z = $3 * (10 ** $4);
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        # 0 1 1
        $x = $1; $y = $2 * (10 ** $3); $z = $4 * (10 ** $5);
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        # 1 0 1
        $x = $1 * (10 ** $2); $y = $3; $z = $4 * (10 ** $5); 
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        # 1 0 0
        $x = $1 * (10 ** $2); $y = $3; $z = $4;
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
        # 1 1 0
        $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5;
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
        # 0 1 0
        $x = $1; $y = $2 * (10 ** $3); $z = $4;
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } elsif ($mifContents[$surfLine] =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        # 0 0 0
        $x = $1; $y = $2; $z = $3;
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);

      } else {
        $line = $surfLine - 1;
        pop(@edgeA); pop(@edgeB); #strip the erroneous point from the end of the graph arrays
        last;
      }
    }
    for ($point=0;$point<@ailCoords_x;$point++) {
      $ailCoords_x[$point] *= 10; 
      $ailCoords_y[$point] *= 10;
      @ailCoords_z[$point] *= 10;
    }
#    checkDuplicates(\@ailCoords_x);
    printSurf(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB);
  }
}

print TOP "\<\/topology\>\n";
close TOP;

#this is a tool for debugging - not really needed
sub checkDuplicates {

  my ($array) = @_; $nPoints = @$array;
  print "CHECKING DUPLICATES FOR $array POINTS\n";
  for ($i=0;$i<@$array;$i++) {

    $store = @$array[$i];

    for ($j=0;$j<@$array;$j++) {
      if (@$array[$j] == $store && $i != $j) {
        print "DUPLICATE FOUND\n";
      }
    }
  }

}

sub reformatSurface {

  my ($xPoints,$yPoints,$zPoints) = @_;
  my @isRedundant; my @xNew, @yNew, @zNew;

  for ($i=0;$i<@xPoints;$i++) {
    $isRedundant[$i] = 0;
  }

  $n_x = @xPoints; $n_y = @yPoints; $n_z = @zPoints;
  if ($n_x == $n_y && $n_y == $n_z) {

    for ($point=0;$point<@xPoints;$point++) {

      if ($isRedundant[$point] == 1) {
        next;
      } else {

        push(@xNew,$xPoints[$point]); push(@yNew,$yPoints[$point]); push(@zNew,$zPoints[$point]);

        $k = @xNew - 1;

        for ($j=$point+1;$j<@xPoints;$j++) {

          if ($xPoints[$point] == $xPoints[$j] && $yPoints[$point] == $yPoints[$j] && $zPoints[$point] == $zPoints[$j]) {
            $isRedundant[$j] = 1; 
            for ($m=0;$m<@edges;$m++) {
              if ($edges[0][$m] == j) {
                $edges[0][$m] = k;
              } elsif ($edges[1][$m] == j) {
                $edges[1][$m] = k;
              }
            }
          }

        }

      }

    }
  } else {
    die "ERROR: MISMATCHED COORDINATE ARRAYS IN reformatSurface SUBROUTINE\n";
  }

}

sub printGraph {

  my ($edgeA, $edgeB) = @_;

  $n_A = @$edgeA; $n_B = @$edgeB;
  if ($n_A == $n_B) {

    for ($edge=0;$edge<@$edgeA;$edge++) {
      print TOP "    \<edge\>";
      print TOP " \<A\>@$edgeA[$edge]\<\/A\>";
      print TOP " \<B\>@$edgeB[$edge]\<\/B\>";
      print TOP " \<\/edge\>\n";
    }

  } else {
    print "N_A = $n_A\nN_B = $n_B\n";
    die "ERROR: MISMATCHED GRAPH ARRAYS IN printGraph SUBROUTINE\n";
  }
}

sub printLine {

  #sub must receive three lists as references (i.e. \@array1, \@array2, \@array3)
  my ($xPoints, $yPoints, $zPoints) = @_;
  $nPoints = scalar(@$xPoints);
#  print "writing $nPoints points\n";

  print TOP "  \<LINE\>\n";
  print TOP "    \<A\>$atomA\<\/A\>\n";
  print TOP "    \<B\>$atomB\<\/B\>\n";

  for ($point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }
  print TOP "  \<\/LINE\>\n";

}

sub printSurf {

  #sub must receive three lists as references (i.e. \@array1, \@array2, \@array3)
  my ($xPoints, $yPoints, $zPoints, $edgeA, $edgeB) = @_;
  $nPoints = scalar(@$xPoints);
#  print "writing $nPoints points\n";

  print TOP "  \<SURFACE\>\n";
  print TOP "    \<A\>$atom\<\/A\>\n";
  for ($point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }

  printGraph(\@$edgeA,\@$edgeB);

  print TOP "  \<\/SURFACE\>\n";

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
