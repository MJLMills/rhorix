$removeRedundant = 0;
$mifFile = "ALANINE0000\.mif";

open(MIF,"<","$mifFile") || die "ERROR: FILE $mifFile DOES NOT EXIST\n";
@mifContents = <MIF>;
close MIF;
chomp(@mifContents);

open(TOP,">","new\.top");
print TOP "\<topology\>\n";

for ($line=0;$line<@mifContents;$line++) {
  
  #PARSE AN ATOMIC INTERACTION LINE
  if ($mifContents[$line] =~ m/AIL\s+\d+\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/) {

    $atomA = "$1$2"; 
    $atomB = "$3$4";
    #sometimes the AIL ID is printed twice - skip to next $line if so
    if ($mifContents[$line+1] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
   
      my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;
      for ($ailLine=$line+1;$ailLine<@mifContents;$ailLine++) {
        if ($mifContents[$ailLine] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
          push(@ailCoords_x,$1); push(@ailCoords_y,$2); push(@ailCoords_z,$3);
        } else {
          $line = $ailLine - 1; #jump the parser over the ail coordinates
          last;
        }
      }
      printLine(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z);
    }

  #PARSE ALL CRITICAL POINTS
  } elsif ($mifContents[$line] =~ m/CRIT/) {

    for ($cpLine=$line+1;$cpLine<@mifContents;$cpLine++) {
      if ($mifContents[$cpLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        $cpType = $1; $x = $2; $y = $3; $z = $4;
        $rank = getRank("$cpType");
        $signature = getSignature("$cpType");
        printCP();

      } else {
        $line = $cpLine - 1; #jump the parser over the critical points
        last;
      }
    }

  #PARSE AN INTERATOMIC OR BOUNDING SURFACE
  } elsif ($mifContents[$line] =~ m/atom\s+(\w+)\_(\d+)/ || $mifContents[$line] =~ m/surf\s+(\w+)\_(\d+)/) {

    $atom = "$1$2";
    if ($mifContents[$line+1] =~ m/(\w+)\s+(\d+)/) {
      print "READING SURFACE OF ATOM $atom ASSOCIATED WITH $1 $2\: ";
    } else {
      die "ERROR READING ASOOCIATED CP FOR SURFACE\n";
    }
    $pointID = 0;
    #read the surface in - mifs are not in a consistent format so all possibilities are needed
    #ORDER IS SUPER IMPORTANT!!!
    my @edgeA; my @edgeB;
    my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;

    for ($surfLine=$line+2;$surfLine<@mifContents;$surfLine++) {

      my @vertexCoords = parseVertexLine($mifContents[$surfLine]);
      if (@vertexCoords) {
        print "READ COORD PROPERLY\n";
        push(@edgeA,$pointID); $pointID++; push(@edgeB,$pointID);
        push(@ailCoords_x,$x); push(@ailCoords_y,$y); push(@ailCoords_z,$z);
      } else {

        print "READ UNDEF PROPERLY\n";
        $n = @ailCoords_x;
        if ($n > 0) {
          print "$n POINTS READ\n";
          $c++;
          # $line is still currently set to the previously found surf line - set it to the line after the last surface$
          $line = $surfLine;
          pop(@edgeA); pop(@edgeB); #strip the erroneous point from the end of the graph arrays
          #Correct the MIF units
          for ($point=0;$point<@ailCoords_x;$point++) {
            $ailCoords_x[$point] *= 10;
            $ailCoords_y[$point] *= 10;
            @ailCoords_z[$point] *= 10;
          }

        } else {
          #in this case an empty surface was found - jump $line past the two entries surf and cp
          $line = $surfLine;
        }
        last; #debug - just get one surface

      }
    }

    $n = @ailCoords_x;
    if ($n > 0) {
      if ($removeRedundant == 1) {
        reformatSurface(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB);
      } else {
        printSurf(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB);
      }
    } else {
      print "EMPTY SURFACE FOUND FOR ATOM $atom\n";
    }

  }
}

print TOP "\<\/topology\>\n";
close TOP;

sub reformatSurface {

  my ($xPoints,$yPoints,$zPoints,$edgeA,$edgeB) = @_;
  my @isRedundant; my @xNew, @yNew, @zNew;

  for ($i=0;$i<@$xPoints;$i++) {
    $isRedundant[$i] = 0;
  }

  $n_x = @$xPoints; $n_y = @$yPoints; $n_z = @$zPoints;
  if ($n_x == $n_y && $n_y == $n_z && $n_x != 0) {

    $kept = 0;
    for ($point=0;$point<@$xPoints;$point++) {
      if ($isRedundant[$point] == 1) {
        next;
      } else {
        push(@xNew,@$xPoints[$point]); push(@yNew,@$yPoints[$point]); push(@zNew,@$zPoints[$point]);
        $kept++;

        for ($j=$point;$j<@$xPoints;$j++) {

          if (@$xPoints[$point] == @$xPoints[$j] && @$yPoints[$point] == @$yPoints[$j] && @$zPoints[$point] == @$zPoints[$j]) {
            if ($point != $j) { $isRedundant[$j] = 1; }
            $rep = $kept - 1;
            for ($m=0;$m<@$edgeA;$m++) {
              if (@$edgeA[$m] == $j) {
                @$edgeA[$m] = $kept - 1;
              } 
              if (@$edgeB[$m] == $j) {
                @$edgeB[$m] = $kept - 1;
              }
            }
          }

        }

      }

    }
    if ($n_x > 0) {
      $n_redundant = 0;
      for ($i=0;$i<@$xPoints;$i++) {
        if ($isRedundant[$i] == 1) { $n_redundant++; };
      } 
      $percent = ($n_redundant / $n_x) * 100; $remains = @xNew;
      printf "%d REDUNDANT POINTS \(OF $n_x\) REMOVED \(%5.2f \%\) LEAVING %d\n",$n_redundant,$percent,$remains;
      printSurf(\@xNew, \@yNew, \@zNew, \@$edgeA, \@$edgeB);
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

  print  TOP "  \<CP\>\n";
  print  TOP "    \<type\>$cpType\<\/type\>\n";
  print  TOP "    \<rank\>$rank\<\/rank\>\n";
  print  TOP "    \<signature\>$signature\<\/signature\>\n";
  printf TOP "    \<x\>%8.5f\<\/x\>", $x;
  printf TOP "\<y\>%8.5f\<\/y\>", $y;
  printf TOP "\<z\>%8.5f\<\/z\>\n", $z;
  print  TOP "  \<\/CP\>\n";

}

sub parseVertexLine {

  $line = "$_[0]";
  local $x = undef; local $y = undef; local $z = undef;

  print "PARSING $line\n";

  if ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5 * (10 ** $6);
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1; $y = $2; $z = $3 * (10 ** $4);
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1; $y = $2 * (10 ** $3); $z = $4 * (10 ** $5);
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1 * (10 ** $2); $y = $3; $z = $4 * (10 ** $5); 
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
    $x = $1 * (10 ** $2); $y = $3; $z = $4;
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
    $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5;
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
    $x = $1; $y = $2 * (10 ** $3); $z = $4;
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
    $x = $1; $y = $2; $z = $3;
  }
  
  if (defined $x) {
    print "VECTOR IS DEFINED";
    @vector = ($x, $y, $z);
    return @vector;
  } else {
    return;
  }

}

sub getRank {

  $type = "$_[0]";
  if ($type == "bcp" || $type == "rcp" || $type = "ccp") {
    return 3;
  } else {
    return 3;
  }
}

sub getSignature {

  $type = "$_[0]";
  if ($type == "bcp") {
    return -1;
  } elsif ($type == "rcp") {
    return 1;
  } elsif ($type == "ccp") {
    return 3;
  } else {
    return -3;
  }

}

