#!/usr/bin/perl -w
# Dr. Matthew J L Mills - RhoRix
# Convert morphy mif files to the top format

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use Utilities qw(checkArgs readFile);
use TopUtils qw(getRank getSignature);
use WriteTopology qw(writeTopologyXML);

#### Script Options ###

$removeRedundant = 1;  # The .mif filetype includes redundant information on triangulated surfaces. Flag to remove or keep this info.
$printEdges      = 0;  # Print edges to the .top file rather than faces.
$factor          = 10; # Data in .mif files is often scaled - this factor removes the scaling.

# Read the .mif file

$mifFile = checkArgs(\@ARGV,"mif");
@mifContents = readFile($mifFile); # returns ref to array, not array

$systemName = stripExt($mgpvizFile,"mgpviz");

if (dirname(__FILE__) =~ m/(.*)\/conversionScripts/) {
  $dtdPath = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtdPath = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

my @source_information = ("unknown","unknown","unknown","MORPHY"); # perhaps the morphy version can be parsed from the MOUT?

parseMif();

# we will initially call parseMif to get all available data from the input file
# ...
# we are eventually going to call writeTopologyXML from writeTopology.pm with info parsed from the mif
#writeTopologyXML($dtdPath,                   #  0 done
#                 $systemName,                #  1 done
#                 $sourceInformation,         #  2 done
#                 $elements,                  #  3 NUCLEI
#                 $nuclearIndices,            #  4
#                 $nuclearCoordinates,        #  5
#                 $cpIndices,                 #  6 CRITICAL POINTS
#                 $ranks,                     #  7
#                 $signatures,                #  8
#                 $cpCoordinates,             #  9
#                 $scalarProperties,          # 10
#                 $ails,                      # 11 MOLECULAR GRAPH
#                 $indices,                   # 12
#                 $props,                     # 13
#                 $atomic_surface_coords,     # 14 ATOMIC SURFACES
#                 $atomic_surface_properties, # 15
#                 $atomic_surface_indices,    # 16
#                 $ring_surface_coords,       # 17 RING SURFACES
#                 $ring_surface_indices,      # 18
#                 $ring_surface_props,        # 19
#                 $envelope_coords,           # 20 ENVELOPES
#                 $envelope_properties,       # 21
#                 $envelope_indices,          # 22
#                 $atomic_basin_coords,       # 23
#                 $atomic_basin_properties,   # 24
#                 $atomic_basin_indices);     # 25


# now need an overarching parseMif subroutine

# Parse the .mif file, printing the .top file as you go

# This mixed thing here is the template for each parsing subroutine that needs to be implemented
# this code will go in the parseMif module and be called here instead
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
