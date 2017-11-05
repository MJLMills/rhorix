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

  ($ails, $indices, $props) = parseMolecularGraphFromMif($mifContents,$factor,$cp_indices,$cp_coordinates);

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
         $cp_scalar_properties,
         $ails,
         $indices,
         $props;

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
    my $factor = $_[1];
    my @ail_coords; 

    for ($slice_line=0; $slice_line<@mif_slice; $slice_line++) {
      if ($mif_slice[$slice_line] =~ m/H\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
        my @position_vector = ($1/$factor, $2/$factor, $3/$factor);
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
    $r = distance($point,$cp_coords[$cp]);
    if ($r < $closest_distance) {
      $closest_distance = $r;
      $closest_index = $cp_indices[$cp];
    }
  }

  return $closest_index;

}

# Arguments - [0] - Reference to array containing lines of the mif file
sub parseMolecularGraphFromMif {

  @mifContents = @{$_[0]};
  $factor      = $_[1];
  $cp_indices  = $_[2];
  $cp_coords   = $_[3];

  # output references to these arrays, which we will build by parsing the file
  my @ails;
  my @indices;
  my @props;

  for ($line=0; $line<@mifContents; $line++) {

    if ($mifContents[$line] =~ m/AIL\s+\d+\s+\w+\s+\d+\s+\w+\s+\d+/) {

      #sometimes the AIL header is printed twice - skip to next $line if so
      if ($mifContents[$line+1] =~ m/AIL\s+\d+\s+\w+\s+\d+\s+\w+\s+\d+/) { $line++; }

      # first parse the AIL coordinates from the mif

      my $max = scalar @mifContents;
      my @slice = @mifContents[$line+1 .. $max];
      $ail_coords = parseAILFromMif(\@slice,$factor);

      $index_a = findClosestCPToPoint(@{$ail_coords}[0],$cp_coords,$cp_indices);
      $index_b = findClosestCPToPoint(@{$ail_coords}[-1],$cp_coords,$cp_indices);

      # Locate the pair of points on the AIL that differ the least - these will each be very close to the BCP (differing only by capture settings in MORPHY)
      # The indices of these two points become demarcation between GP a and GP b, and either can be used to find the BCP.
      @ail = @{$ail_coords};
      $min_distance = 1000000;
      for($point=0; $point<@ail-1; $point++) {
        $r = distance($ail[$point],$ail[$point+1]);
        if ($r < $min_distance) {
          $min_distance = $r;
          $final_point_a = $point;
        }
      }

      $bcp_index = findClosestCPToPoint($ail[$final_point_a],$cp_coords,$cp_indices);

      my @gp_a = @ail[0 .. $final_point_a];
      my @gp_b = @ail[$final_point_a+1 .. -1];

      my @maps_a;
      foreach(@gp_a) {
        my $scalars_a = {};
        push(@maps_a,$scalars_a);
      }

      my @maps_b;
      foreach(@gp_b) {
        my $scalars_b = {};
        push(@maps_b,$scalars_b);
      }

      my @position_vectors = (\@gp_a,\@gp_b);
      push(@ails,\@position_vectors);
      my @maps = (\@maps_a,\@maps_b);
      push(@props,\@maps);

      my @a = ($index_a,$bcp_index); my @b = ($index_b,$bcp_index);
      @cpIndices = (\@a,\@b);
      push(@indices,\@cpIndices);

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
