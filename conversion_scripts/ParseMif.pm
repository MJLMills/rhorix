#!/usr/bin/perl -w
# ParseMif Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseMif;
require Exporter;
use TopUtils qw(getRank getSignature);

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(parseMif);
our $VERSION   = 1.0;

### Subroutines ###

# public subroutine to call private subroutines
sub parseMif {

  # Input Arguments
  my $mifContents      = $_[0];
  my $factor           = $_[1];
  my $remove_redundant = $_[2];
  my $print_edges      = $_[3];

  ($nuclear_elements, $nuclear_coordinates, $nuclear_indices) = parseNucleiFromMif($mifContents,$factor);

  ($cp_indices, $ranks, $signatures, $cp_coordinates, $cp_scalar_properties) = parseCPsFromMif($mifContents,$factor);

  #($ails, $indices, $props) = 
  parseMolecularGraphFromMif($mifContents,$factor);

  #($atomic_surface_coords, $atomic_surface_properties, $atomic_surface_indices, $envelope_coords, $envelope_properties, $envelope_indices) = 
  # This needs to be fixed to return the appropriate arrays
  #parseSurfacesFromMif($mifContents,$remove_redundant,$print_edges);

  return $nuclear_elements,
         $nuclear_indices,
         $nuclear_coordinates,
         $cp_indices,
         $ranks,
         $signatures,
         $cp_coordinates,
         $cp_scalar_properties;

#$ails,
#$indices,
#$props,

#$atomic_surface_coords,
#$atomic_surface_properties,
#$atomic_surface_indices,
#$envelope_coords,
#$envelope_properties,
#$envelope_indices

}

# This routine parses all nuclei from the mif file..
# Arguments - [0] - reference to an array containing the lines of the mif file
#             [1] - inverse scale factor for the Cartesian coordinates
sub parseNucleiFromMif {

  my @mifContents = @{$_[0]};
  my $factor = $_[1];

  my @nuclear_elements;
  my @nuclear_coordinates;
  my @nuclear_indices;

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/CRIT/) {
      $nuclear_index = 1;
      for ($cLine=$line+1; $cLine<@mifContents; $cLine++) {
        if ($mifContents[$cLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

          my $label = $1;          
          if ($label !~ m/cp/) {
            my @position_vector = ($2/$factor, $3/$factor, $4/$factor);
            push(@nuclear_coordinates,\@position_vector);
            push(@nuclear_elements,$label);
            push(@nuclear_indices,$nuclear_index); $nuclear_index++;
          }
        }
      }
    }
  }

  return \@nuclear_elements, \@nuclear_coordinates, \@nuclear_indices; 

}

sub parseCPsFromMif {

  my @mifContents = @{$_[0]};
  $factor = $_[1];

  my @cp_indices;
  my @ranks;
  my @signatures;
  my @cp_coordinates;
  my @cp_scalar_properties;

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/CRIT/) {

      $cp_index = 1;
      for ($cLine=$line+1; $cLine<@mifContents; $cLine++) {

        if ($mifContents[$cLine] =~ m/(\w+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

          my $label = $1;
          my @position_vector = ($2/$factor, $3/$factor, $4/$factor);

          if ($1 !~ m/cp/) { $label = "ccp"; }

          push(@cp_coordinates,\@position_vector);
          $rank = getRank($label);
          $signature = getSignature($label);
          push(@ranks,$rank);
          push(@signatures,$signature);
          my $empty_hash = {}; # no scalar properties are written to the mif
          push(@cp_scalar_properties,$empty_hash);
          push(@cp_indices,$cp_index); $cp_index++;

        }
      }
    }
  }

  return \@cp_indices, \@ranks, \@signatures, \@cp_coordinates, \@cp_scalar_properties;

}

sub parseSurfacesFromMif {

  @mifContents = @{$_[0]};
  $removeRedundant = $_[1];
  $printEdges = $_[2];

  # create the arrays that will be returned

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/atom\s+(\w+)(\d+)/ || $mifContents[$line] =~ m/surf\s+(\w+)(\d+)/) {

      $atom = "$1$2";
      if ($mifContents[$line+1] !~ m/(\w+)\s+(\d+)/) {
        die "ERROR - Malformed File \(line $line\)\: Cannot read CP associated with surface $atom\n\n";
      }

      # these will be filled for this surface then pushed to a collected array
      my @edgeA; my @edgeB; my @faceA; my @faceB; my @faceC;
      my @ailCoords_x; my @ailCoords_y; my @ailCoords_z;

      $vertex = 1; $pointID = 0;
      SURF_LOOP: for ($surfLine=$line+2; $surfLine<@mifContents; $surfLine++) {

        my @vertexCoords;
        if ($mifContents[$surfLine] =~ m/(.*)\s+(.*)\s+(.*)/) {
          @vertexCoords = ($1, $2, $3);
        }

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
            print STDERR "$n POINTS READ \($nTriangles TRIANGLES\)\n";
            # $line is still currently set to the previously found surf line - set it to the line after the last surface
            $line = $surfLine;
            #Correct the MIF units - this should use $factor?

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
          # this should return the reformatted data instead of writing it out in-routine
          reformatSurface(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB, \@faceA, \@faceB, \@faceC, $printEdges);
        } else {
          # push the data to the appropriate arrays rather than writing out
          #printSurf(\@ailCoords_x, \@ailCoords_y, \@ailCoords_z, \@edgeA, \@edgeB, \@faceA, \@faceB, \@faceC);
        }
      } else {
        print STDERR "EMPTY SURFACE FOUND FOR ATOM $atom\n";
      }
      $c++;

    }

  }

  # return the arrays that have now been filled

}

sub parseAILFromMif {

    my @mif_slice = @{$_[0]};
    my @ail_coords; 

    for ($line=0; $line<@mif_slice; $line++) {
      if ($mifContents[$line] =~ m/H\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        my @position_vector = ($1, $2, $3);
        push(@ail_coords,\@position_vector);
      } else {
        last;
      }

    }

    return \@ail_coords;

}

sub findClosestCPToPoint {

  $point      = $_[0];
  @cp_coords  = @{$_[1]};
  @cp_indices = @{$_[2]};

  $closest_index = -1;
  $closest_distance = 100000.0;
  for ($cp=0; $cp<@cp_coords; $cp++) {
    $r = $distance(\@point,\@cp_coords[$cp]);
    if ($r < $closest_distance) {
      $closest_distance = $r;
      $closest_index = $cp_indices[$cp];
    }
  }

  return $closest_index;

}

# Arguments - [0] - Reference to array containing lines of the mif file
sub parseMolecularGraphFromMif {

  @mifContents    = @{$_[0]};
  $factor         = $_[1];

  # output references to these arrays, which we will build by parsing the file
  my @ails;
  my @indices;
  my @props;

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/AIL\s+\d+\s+\w+\s+\d+\s+\w+\s+\d+/) {

      #sometimes the AIL header is printed twice - skip to next $line if so
      if ($mifContents[$line+1] =~ m/AIL\s+\d+\s+\w+\s+\d+\s+\w+\s+\d+/) { $line++; }

      # first parse the AIL coordinates from the mif
      if ($mifContents[$line+1] =~ m/H\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        $ail_coords = parseAILFromMIF($mifContents[$line+1 ..]);
      }

      $index_a = findClosestPointToCP($ail_coords[0]);
      $index_b = findClosestPointToCP($ail_coords[-1]);

      # then take the central point on the AIL - if odd take the middle one, if even average the central 2
      $n_points = scalar @{$ail_coords};
      if ($n_points % 2 == 0) {
        $point_i = $n_points/2;
        $point_j = $point_i + 1;
        for($i=0; $i<3; $i++) {
          $midpoint[$i] = ($point_i - $point_j) / 2;
        }
      } else {
        $midpoint = @{$ail_coords}[($n_points+1)/2];
      }

      my @gp_a;
      my @gp_b;
      # run over the ail coords adding them to the appropriate array
      # distance from BCP will decrease along the path, when it starts to increase switch to B
      my @distance_to_bcp;
      foreach(@{$ail_coords}) {
        
      }

      # this must happen twice, once for each nuclear index
#      my @index = ($nuclear_index,$closest_index);
#      push(@indices,\@index);
#      push(@ails,)
#      $scalars = {};
#      push(@props,$scalars)
    }
  }

  return \@ails, \@indices, \@props;

}

sub distance {

  @vector_a = @{$_[0]};
  @vector_b = @{$_[1]};

  $sum = 0.0;
  for ($i=0; $i<3; $i++) {
    $diff = $vector_a[$i] - $vector_b[$i];
    $sum += $diff * $diff;
  }

  return sqrt($sum);

}

sub reformatSurface {

  my ($xPoints,$yPoints,$zPoints,$edgeA,$edgeB,$faceA,$faceB,$faceC,$printEdges) = @_;
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
      # rather than print this should return the reduced data to the main routine
      #printSurf(\@xNew, \@yNew, \@zNew, \@$edgeA, \@$edgeB, \@$faceA, \@$faceB, \@$faceC);
    }

  } else {
    die "ERROR: MISMATCHED COORDINATE ARRAYS IN reformatSurface SUBROUTINE\n";
  }

}
