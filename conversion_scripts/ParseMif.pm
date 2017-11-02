# ParseMif Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseMif;
require Exporter;
use Utilities qw(readFile);

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(parseMif);
our $VERSION   = 1.0;

### Subroutines ###
# To be replaced with their .mif equivalents:

# public subroutine to call private subroutines
sub parseMif {

  ($nuclear_elements, $nuclear_coordinates, $nuclear_indices, $cp_indices, $ranks, $signatures, $cp_coordinates, $cp_scalar_properties) = parseNucleiFromMif($_[0]);
  ($ails, $indices, $props) = parseMolecularGraphFromMif($_[0],$cp_coordinates,$cp_indices);

  parseSurfacesFromMif();

  return $nuclear_elements,
         $nuclear_indices,
         $nuclear_coordinates,
         $cp_indices,
         $ranks,
         $signatures,
         $cp_coordinates,
         $cp_scalar_properties;

# These come from parsing the molecular graph
#         $ails,
#         $indices,
#         $props,

# These come from parsing the surface data
#         $atomic_surface_coords,
#         $atomic_surface_properties,
#         $atomic_surface_indices,
#         $envelope_coords,
#         $envelope_properties,
#         $envelope_indices,


# There is no ring surface data in the mif file
#         $ring_surface_gps
#         $ring_surface_indices
#         $ring_surface_props
# There is no basin data in the mif file
#         $atomic_basin_coords
#         $atomic_basin_properties
#         $atomic_basin_indices

}

# This routine should parse nuclei and CPs from the mif since they are in ths same block.
# Arguments - [0] - reference to an array containing the lines of the mif file
#             [1] - inverse scale factor for the Cartesian coordinates
sub parseNucleiAndCPsFromMif {

  my @mifContents = @{$_[0]};
  my $factor = $_[1];

  my @nuclear_elements;
  my @nuclear_coordinates;
  my @nuclear_indices;
  my @cp_indices;
  my @ranks;
  my @signatures;
  my @cp_coordinates;
  my @cp_scalar_properties;

  for ($line=0; $line<@mifContents; $line++) {
    if ($mifContents[$line] =~ m/CRIT/) {
      for ($cLine=$line+1; $cLine<@mifContents; $cLine++) {
        $cp_index = 1; $nuclear_index = 1;
        if ($mifContents[$cLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

          my $label = $1;
          my @position_vector = ($2/$factor, $3/$factor, $4/$factor);
          push(@cp_coordinates,\@position_vector);
          push(@ranks,getRank($label));
          push(@signatures,getSignature($label));
          push(@cp_indices); $cp_index++;
          
          if ($label !=~ m/cp/) {
            push(@nuclear_coordinates,\@position_vector);
            push(@nuclear_elements,$1);
            push(@nuclear_indices,$nuclear_index); $nuclear_index++;
          }
        }
      }
    }
  }

  return \@nuclear_elements, \@nuclear_coordinates, \@nuclear_indices, \@cp_indices, \@ranks, \@signatures, \@cp_coordinates, \@cp_scalar_properties;

}

sub parseSurfacesFromMif {

  # Parse an interatomic or bounding surface

  if ($mifContents[$line] =~ m/atom\s+(\w+)(\d+)/ || $mifContents[$line] =~ m/surf\s+(\w+)(\d+)/) {

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

  }

}

# Arguments - [0] - Reference to array containing lines of the mif file
sub parseMolecularGraphFromMif {

  @mifContents    = @{$_[0]};
  @cp_coordinates = @{$_[1]};
  @cp_indices     = @{$_[2]};
  $factor         = $_[3]; # maybe keep this in the mif2top script and apply it after the parsing

  # output references to these arrays, which we will build by parsing the file
  my @ails;
  my @indices;
  my @props; # there are no point scalar properties stored in a mif file

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/AIL\s+\d+\s+\w+\s+(\d+)\s+\w+\s+(\d+)/) {

      $indexA = $1; $indexB = $2; # these are the necessary nuclear indices but BCP index is unknown

      #sometimes the AIL header is printed twice - skip to next $line if so
      if ($mifContents[$line+1] =~ m/AIL\s+\d+\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/) { $line++; }

      if ($mifContents[$line+1] =~ m/H\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
   
        my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;
        for ($ailLine=$line+1; $ailLine<@mifContents; $ailLine++) {

          if ($mifContents[$ailLine] =~ m/H\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
            push(@ailCoords_x,$1/$factor);
            push(@ailCoords_y,$2/$factor);
            push(@ailCoords_z,$3/$factor);
          } else {
            #the AIL has been parsed; jump the main loop over the coordinates of this AIL and continue parsing the file
            $line = $ailLine - 1;
            last;
          }

        }

        # push the AIL information to the appropriate arrays here
        # which means apply some approximate method of finding out the BCP
        # assuming a straight AIL, the midpoint of the first and last point is a good guess, then can scan the BCPs to find the closest
        # means passing the CP coordinates into this routine

        # @midpoint = (cp_coordinates[$indexA-1] + cp_coordinates[$indexB-1]) / 2; in each dimension is the midpoint
#        $closestIndex = -1; $closestDistance = 10000.0;
#        for($cp=0; $cp<@cp_indices; $cp++) {
#          $r = distance(\@midpoint,\@cp_coordinates[$cp]);
#          if ($r < $closest) {
#            $closestDistance = $r;
#            $closestIndex = $cp_indices[$cp];
#          }
#        }

         # now we should have the index of the BCP closest to the AIL midpoint and can store data
        #printLine(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z);

      }
    }
  }

  return $ails, $indices, $props;

}

sub distance {

  @vector_a = @{$_[0]};
  @vector_b = @{$_[1]};

  $sum = 0.0;
  for ($i=0; $i<3; $i++) {
    $diff = $vector_a[$i] - $vector_b[$i]
    $sum += $diff * $diff;
  }

  return sqrt($sum);

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

#sub parseGradientPath {}
#sub parseSourceInformationFromMif {} # not possible - maybe from a mout?
#sub parseRingSurfacesFromMif {} # ring lines not present in mif
#sub determineRings {} # leave empty
#sub determineCages {} # leave empty

