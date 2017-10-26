#!/usr/bin/perl -w
# Dr. Matthew J L Mills - RhoRix
# Convert morphy mif files to the top format

use Utilities qw(checkArgs readFile);

$removeRedundant = 1;
$printEdges = 0;
$factor = 10;

# Read the .mif file

$mifFile = checkArgs(\@ARGV,"mif");
@mifContents = readFile($mifFile);

# Create the .top file

$mifFile =~ m/(.*)\.mif/;
$topFile = "$1\.top";
open(TOP,">","$topFile") || die "Cannot create topology file\: $topFile\n";
print TOP "\<topology\>\n";

# Parse the .mif file, printing the .top file as you go

$c = 0;
MAIN_LOOP: for ($line=0; $line<@mifContents; $line++) {
  
    # Parse a single atomic interaction line

    if ($mifContents[$line] =~ m/AIL\s+\d+\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/) {

      $atomA = "$1$2";  $atomB = "$3$4";
      #sometimes the AIL ID is printed twice - skip to next $line if so
      if ($mifContents[$line+1] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
   
        my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;
        AIL_LOOP: for ($ailLine=$line+1; $ailLine<@mifContents; $ailLine++) {

          if ($mifContents[$ailLine] =~ m/\w+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
            push(@ailCoords_x,$1/$factor);
            push(@ailCoords_y,$2/$factor);
            push(@ailCoords_z,$3/$factor);
          } else {
            #the AIL has been parsed; jump the main loop over the coordinates of this AIL and continue parsing the file
            $line = $ailLine - 1;
            last AIL_LOOP;
          }

        }
        printLine(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z);
      }

    # Parse all of the critical points in the file

    } elsif ($mifContents[$line] =~ m/CRIT/) {

      CRIT_LOOP: for ($cpLine=$line+1; $cpLine<@mifContents; $cpLine++) {
        if ($mifContents[$cpLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

          $cpType = $1;
          $x = $2 / $factor;
          $y = $3 / $factor;
          $z = $4 / $factor;
          
          $rank = getRank("$cpType");
          $signature = getSignature("$cpType");
          printCP($cpType,$rank,$signature,$x,$y,$z);

        } else {

          #the CPs have been parsed; jump the main loop over the coordinates of the CPs and continue parsing the file
          $line = $cpLine - 1; #jump the parser over the critical points
          last CRIT_LOOP;

        }
      }

    # Parse an interatomic or bounding surface

    } elsif ($mifContents[$line] =~ m/atom\s+(\w+)(\d+)/ || $mifContents[$line] =~ m/surf\s+(\w+)(\d+)/) {

     print "SURFACE\: $mifContents[$line]\n";

      $atom = "$1$2"; print "$atom\n";
      if ($mifContents[$line+1] =~ m/(\w+)\s+(\d+)/) {
        print "READING SURFACE OF ATOM $atom ASSOCIATED WITH $1 $2\: ";
      } else {
        die "ERROR - Malformed File \(line $line\)\: Cannot read CP associated with surface $atom\n\n";
      }

      my @edgeA; my @edgeB; my @faceA; my @faceB; my @faceC;
      my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;

      $vertex = 1; $pointID = 0;
      SURF_LOOP: for ($surfLine=$line+2; $surfLine<@mifContents; $surfLine++) {

        my @vertexCoords = parseVertexLine($mifContents[$surfLine]);
        if (@vertexCoords) {

          push(@ailCoords_x,$vertexCoords[0]); 
          push(@ailCoords_y,$vertexCoords[1]); 
          push(@ailCoords_z,$vertexCoords[2]);

          if ($vertex == 1) {
            push(@faceA,$pointID); 
            push(@faceB,$pointID+1); 
            push(@faceC,$pointID+2); 
          }

          if ($vertex == 1) { #connect A to B
            push(@edgeA,$pointID); 
            $pointID++; 
            push(@edgeB,$pointID);
          } elsif ($vertex == 2) { # connect B to C
            push(@edgeA,$pointID); 
            $pointID++; 
            push(@edgeB,$pointID);
          } elsif ($vertex == 3) { # connect C to A
            push(@edgeA,$pointID); 
            push(@edgeB,$pointID-2); 
            $pointID++;
          }

          #$vertexCount++;

          #cycle the vertex of the triangle
          if ($vertex == 3) { $vertex = 1 } else { $vertex++ }

        } else {

          $n = @ailCoords_x;
          if ($n > 0) {

            $nTriangles = $n / 3;
            print "$n POINTS READ \($nTriangles TRIANGLES\)\n";
            # $line is still currently set to the previously found surf line - set it to the line after the last surface
            $line = $surfLine;
            #Correct the MIF units

            for ($point=0;$point<@ailCoords_x;$point++) {
              #$ailCoords_x[$point] *= 10;
              #$ailCoords_y[$point] *= 10;
              #$ailCoords_z[$point] *= 10;
            }

            $line = $surfLine - 1;
            last SURF_LOOP;

          } else {
            #in this case an empty surface was found - jump $line past the two entries surf and cp
            $line = $surfLine;
            last SURF_LOOP;
          }
        }
      } # END SURF_LOOP
      
      $n = @ailCoords_x;
      if ($n > 0) {
        if ($removeRedundant == 1) {
          reformatSurface(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB, \@faceA, \@faceB, \@faceC);
        } else {
          printSurf(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB, \@faceA, \@faceB, \@faceC);
        }
      } else {
        print "EMPTY SURFACE FOUND FOR ATOM $atom\n";
      }
      $c++;

    } # END PICK_READER

} # end MAIN_LOOP

# Close up the topology file

print TOP "\<\/topology\>\n";
close TOP;


### SUBROUTINES ###

sub reformatSurface {

  my ($xPoints,$yPoints,$zPoints,$edgeA,$edgeB,$faceA,$faceB,$faceC) = @_;
  my @isRedundant; 
  my @xNew; 
  my @yNew; 
  my @zNew;

  $start = time;

  for ($i=0;$i<@$xPoints;$i++) {
    $isRedundant[$i] = 0;
  }

  $n_x = @$xPoints; $n_y = @$yPoints; $n_z = @$zPoints;
  if ($n_x == $n_y && $n_y == $n_z && $n_x != 0) {

    $kept = 0;
    CHECK_POINTS: for ($point=0;$point<@$xPoints;$point++) {

      if ($isRedundant[$point] == 1) {
        next CHECK_POINTS;
      } else {
        push(@xNew,@$xPoints[$point]); push(@yNew,@$yPoints[$point]); push(@zNew,@$zPoints[$point]);
        $kept++; $rep = $kept - 1;

        if ($printEdges == 1) {
          CORRECT_EDGES: for ($j=$point;$j<@$xPoints;$j++) {

#          if ($isRedundant[$j] == 1) { next CORRECT_EDGES; }

            if (@$xPoints[$point] == @$xPoints[$j] && @$yPoints[$point] == @$yPoints[$j] && @$zPoints[$point] == @$zPoints[$j]) {

              if ($point != $j) { $isRedundant[$j] = 1; }

              for ($m=0;$m<@$edgeA;$m++) {
                if (@$edgeA[$m] == $j) {
                  @$edgeA[$m] = $rep;
                } 
                if (@$edgeB[$m] == $j) {
                  @$edgeB[$m] = $rep;
                }
              }
            }
          }
        }

        CORRECT_FACES: for ($j=$point;$j<@$xPoints;$j++) {
        
          if (@$xPoints[$point] == @$xPoints[$j] && @$yPoints[$point] == @$yPoints[$j] && @$zPoints[$point] == @$zPoints[$j]) {

            if ($point != $j) { $isRedundant[$j] = 1; }

            for ($m=0;$m<@$faceA;$m++) {
              if (@$faceA[$m] == $j) { @$faceA[$m] = $rep; }
              if (@$faceB[$m] == $j) { @$faceB[$m] = $rep; }
              if (@$faceC[$m] == $j) { @$faceC[$m] = $rep; }
            }

          }

        }

      }

    }

    $end = time; $elapsed = $end - $start; print "TOOK $elapsed SECONDS TO FIX SURFACE\t";

    if ($n_x > 0) {
      $n_redundant = 0;
      for ($i=0;$i<@$xPoints;$i++) {
        if ($isRedundant[$i] == 1) { $n_redundant++; };
      } 
      $percent = ($n_redundant / $n_x) * 100; $remains = @xNew;
      printf "%d REDUNDANT POINTS \(OF $n_x\) REMOVED \(%5.2f percent\) LEAVING %d\n",$n_redundant,$percent,$remains;
      printSurf(\@xNew, \@yNew, \@zNew, \@$edgeA, \@$edgeB, \@$faceA, \@$faceB, \@$faceC);
    }

  } else {
    die "ERROR: MISMATCHED COORDINATE ARRAYS IN reformatSurface SUBROUTINE\n";
  }

}

sub printFaces {

local ($faceA,$faceB,$faceC) = @_;

  if (@$faceA == @$faceB && @$faceB == @$faceC) {

    for (local $face=0;$face<@$faceA;$face++) {
      print TOP "    \<face\>";
      print TOP "\<A\>@$faceA[$face]\<\/A\>";
      print TOP "\<B\>@$faceB[$face]\<\/B\>";
      print TOP "\<C\>@$faceC[$face]\<\/C\>";
      print TOP " \<\/face\>\n";
    }

  } else {
    #print "N_A = $n_A\nN_B = $n_B\nN_C = @$edgeC\n";
    die "ERROR: MISMATCHED FACE ARRAYS IN printFaces SUBROUTINE\n";
  }

}

sub printGraph {

  local ($edgeA, $edgeB) = @_;
  local $n_A = @$edgeA; 
  local $n_B = @$edgeB;

  if ($n_A == $n_B) {

    for (local $edge=0;$edge<@$edgeA;$edge++) {
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
  local ($xPoints, $yPoints, $zPoints) = @_;
  local $nPoints = scalar(@$xPoints);

  print TOP "  \<LINE\>\n";
  print TOP "    \<A\>$atomA\<\/A\>\n";
  print TOP "    \<B\>$atomB\<\/B\>\n";

  for (local $point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }
  print TOP "  \<\/LINE\>\n";

}

sub printSurf {

  #sub must receive five lists as references (i.e. \@array1, \@array2, \@array3, \@edgesA, \@edgesB)
  local ($xPoints, $yPoints, $zPoints, $edgeA, $edgeB, $faceA, $faceB, $faceC) = @_;
  local $nPoints = scalar(@$xPoints);

  print "PRINTING SURFACE OF $nPoints POINTS\n";

  print TOP "  \<SURFACE\>\n";
  print TOP "    \<A\>$atom\<\/A\>\n";
  for (local $point=0;$point<$nPoints;$point++) {
    print TOP "    \<vector\>";
    printf TOP " \<x\>%8.5f\<\/x\>", @$xPoints[$point];
    printf TOP " \<y\>%8.5f\<\/y\>", @$yPoints[$point];
    printf TOP " \<z\>%8.5f\<\/z\>", @$zPoints[$point];
    print TOP " \<\/vector\>\n";
  }

  #only print the edges if you really want them for some reason. Kept for back-compatability for now
  if ($printEdges == 1) { printGraph(\@$edgeA,\@$edgeB); }
  printFaces(\@$faceA,\@$faceB,\@$faceC);

  print TOP "  \<\/SURFACE\>\n";

}

sub printCP {

  local $cpType = $_[0];
  local $rank   = $_[1];
  local $signature = $_[2];

  local $x = $_[3]; local $y = $_[4]; local $z = $_[5];

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

  local $line = "$_[0]";
  local $x = undef; local $y = undef; local $z = undef;

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
    local @vector = ($x, $y, $z);
    return @vector;
  } else {
    return;
  }

}

sub getRank {

  local $type = "$_[0]";

  if ($type eq "bcp" or $type eq "rcp" or $type eq "ccp") {
    return 3;
  } else {
    return 3;
  }
}

sub getSignature {

  local $type = "$_[0]";

  if ($type eq "bcp") {
    return -1;
  } elsif ($type eq "rcp") {
    return 1;
  } elsif ($type eq "ccp") {
    return 3;
  } else {
    return -3;
  }

}
