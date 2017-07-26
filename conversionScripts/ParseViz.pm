# ParseViz Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseViz;
require Exporter;
use Utilities qw(readFile);

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(parseMgpviz);
our $VERSION   = 1.0;

### Subroutines ###

sub parseMgpviz {

  $sourceInformation = parseSourceInformationFromViz($_[0]);
  # First read the data about the nuclei - elements, unique indices and Cartesian coordinates of each nucleus
  ($elements,$nuclearIndices,$nuclearCoordinates) = parseNucleiFromViz($_[0]);
  # With the nuclei known, read the critical point data (index, rank, signature, position vector and scalar properties at each CP)
  ($cpIndices,$ranks,$signatures,$cpCoordinates,$scalarProperties) = parseCPsFromViz($_[0]);
  # then parse the gradient vector field from the file
  # Read the gradient paths associated with CPs
  ($ails, $indices, $props) = parseMolecularGraphFromViz($_[0]);

  ($ring_surface_gps, $ring_surface_indices, $ring_surface_props) = parseRingSurfacesFromMgpviz($_[0]);

  ($atomic_surface_coords,
   $atomic_surface_properties,
   $atomic_surface_indices,
   $envelope_coords,
   $envelope_properties,
   $envelope_indices,
   $atomic_basin_coords,
   $atomic_basin_properties,
   $atomic_basin_indices) = parseRelatedIasvizFiles($elements,$nuclearIndices,$_[1]);

  return $sourceInformation,
         $elements,
         $nuclearIndices,
         $nuclearCoordinates,
         $cpIndices,
         $ranks,
         $signatures,
         $cpCoordinates,
         $scalarProperties,
         $ails,
         $indices,
         $props,
         $atomic_surface_coords,
         $atomic_surface_properties,
         $atomic_surface_indices,
         $ring_surface_gps,
         $ring_surface_indices,
         $ring_surface_props,
         $envelope_coords,
         $envelope_properties,
         $envelope_indices,
         $atomic_basin_coords,
         $atomic_basin_properties,
         $atomic_basin_indices;

}

sub parseRingSurfacesFromMgpviz {

  @fileContents = @{$_[0]};

  my @rs_gp_coords;
  my @rs_gp_properties;
  my @rs_gp_indices;

  $parseSwitch = 0;
  for($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/Type\s+\=\s+\(3\,\+1\)\s+RCP/) {

      $parseSwitch = 1;
      my @gp_coords;
      my @gp_properties;
      my @gp_indices;

    } elsif ($fileContents[$line] =~ m/^$/ && $parseSwitch == 1) {

      $parseSwitch = 0;
      # save the ring surface and go to next one
      push(@rs_gp_coords,    \@gp_coords);
      push(@rs_gp_properties,\@gp_properties);
      push(@rs_gp_indices,   \@gp_indices);

    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along path from RCP to BCP between atoms\s+\w+(\d+)\s+and\s+\w+(\d+)/) {

      $nPoints = $1;
      @slice = @fileContents[$line+1 .. $line+$nPoints];

      ($gp,$map) = parseGradientPath(\@slice);
      my @indices = ($cpIndex,0); # todo - determine BCP index

      push(@gp_coords,$gp);
      push(@gp_properties,$map);
      push(@gp_indices,\@indices);

    } elsif ($fileContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+=/) {

      $cpIndex = $1;

    }

  }

  return \@rs_gp_coords, \@rs_gp_indices, \@rs_gp_properties;

}

# some GPs of the interatomic surfaces may be present in the mgpviz file in BCP records
# parse the 4 GPs from each BCP and use each quartet to make an IAS
sub parseInteratomicSurfacesFromMgpviz {

  @fileContents = @{$_[0]};

  my @gp_coords;
  my @gp_props;
  my @gp_indices;

  $parseSwitch = 0;
  for($line=0; $line<@fileContents; $line++) {
    if ($fileContents[$line] =~ m/Type\s+=\s+\(3,-1\)\s+BCP/) {
      $parseSwitch = 1;
    } elsif ($fileContents[$line] =~ m/^$/ && $parseSwitch == 1) {
      $parseSwitch = 0;
    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along IAS\s+[+-]EV[12]\s+path from BCP/ && $parseSwitch == 1) {
      # parse the line and push to AIL coords, indices and props
      $nPoints = $1;
      @slice = @fileContents[$line+1 .. $line+$nPoints];
      ($gp, $map) = parseGradientPath(\@slice);
      push(@gp_cooords,$gp);
      push(@gp_props,$map);
      my @inidices = ($cpIndex,0);
      push(@gp_indices,\@indices);

    } elsif ($fileContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+=/) {
      $cpIndex = $1;
    }
  }

  return \@gp_coords, \@gp_props, \@gp_indices;

}

sub parseSourceInformationFromViz {

  foreach(@{$_[0]}) {
    if ($_ =~ m/(AIMExt\s+\(.*\))/) {
      $analysis_software = $1;
      last;
    }
  }

  my @source_information = ("unknown","unknown","unknown","$analysis_software");
  return \@source_information;

}

sub parseNucleiFromViz {

  @fileContents = @{$_[0]};

  my @elements    = ();
  my @indices     = ();
  my @coordinates = ();

  $parseNuclei = 0;
  for($line=0;$line<@fileContents;$line++) {
    if ($fileContents[$line] =~ m/Nuclear Charges and Cartesian Coordinates\:/) {
      $parseNuclei = 1; $line += 3;
    } elsif (($parseNuclei == 1) && ($fileContents[$line] =~ m/([a-zA-Z]+)(\d+)\s+\d+\.\d+\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/)) {

      push(@elements,$1);
      push(@indices,$2);
      my @positionVector = ($3,$4,$5);
      push(@coordinates,\@positionVector);

    } elsif ($parseNuclei == 1) {
      last;
    }
  }

  return \@elements, \@indices, \@coordinates;

}

sub parseCPsFromViz {

  my @fileContents = @{$_[0]};

  my @indices          = ();
  my @ranks            = ();
  my @signatures       = ();
  my @cpCoordinates    = ();
  my @scalarProperties = ();

  for ($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+=\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {

      push(@indices,$1);
      my @positionVector = ($2,$3,$4);
      push(@cpCoordinates,\@positionVector);

      if ($fileContents[$line+1] =~ m/Type\s+\=\s+\((\d+)\,([-+]\d+)\)/) {
        push(@ranks,$1);
        push(@signatures,$2);
      } else {
        die "Error\: Malformed line\: $fileContents[$line+1]\n";
      }

      my %scalarProps;
      if ($fileContents[$line+2] =~ m/\s+Rho\s+\=\s+(-?\d+\.\d+E[+-]\d+)/) {
        $scalarProps{'rho'} = $1;
        push(@scalarProperties,\%scalarProps);
      } else {
        die "Error\: Malformed line\: $fileContents[$line+2]";
      }
      
    }

  }

  return \@indices,\@ranks,\@signatures,\@cpCoordinates,\@scalarProperties;

}

sub parseMolecularGraphFromViz {

  @fileContents = @{$_[0]};

  my @ailList;  # list of pairs of gradient paths, each of which is a list of references to 3-arrays of Cartesians
  my @props; # for each AIL, 2 lists of hashes, each of which maps the string 'rho' to the electron density at that point
  my @cps;   # for each AIL, there are 2 lists of 2 integer critical point indices

  $storeAILs = 0;
  for ($line=0; $line<@fileContents; $line++) {
    
    if ($fileContents[$line] =~ m/CP\#\s+(\d+)/) {
      $cpIndex = $1;
      if ($fileContents[$line+1] =~ m/Type\s+\=\s+\(3,-1\)\s+BCP\s+(\w+\d+)\s+(\w+\d+)/) {
        $storeAILs = 1;
        @nuclei = ($1,$2);
        $fileContents[$line+1] =~ m/Type\s+\=\s+\(3,-1\)\s+BCP\s+[a-zA-Z]+(\d+)\s+[a-zA-Z]+(\d+)/;
        my @a = ($cpIndex,$1); my @b = ($cpIndex,$2);
        @cpIndices = (\@a,\@b);
      } else {
        $storeAILs = 0;
      }

    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along path from BCP to atom\s+(\w+\d+)/) {

      $nPoints = $1;
      $atom    = $2;

      @slice = @fileContents[$line+1 .. $line+$nPoints];

      if ($atom eq $nuclei[0]) {
        ($ail_a, $map_a) = parseGradientPath(\@slice);
      } elsif ($atom eq $nuclei[1]) {
        ($ail_b, $map_b) = parseGradientPath(\@slice);
      }

    } elsif ($fileContents[$line] =~ m/^$/ && $storeAILs == 1) {

      # these are the point objects
      my @position_vectors   = ($ail_a, $ail_b); # 2 lists of position vectors
      my @property_maps      = ($map_a, $map_b); # 2 lists of hashes

      push(@ails,\@position_vectors);
      push(@props,\@property_maps);
      my @indices = @cpIndices;
      push(@cps,\@indices);

    } elsif ($fileContents[$line] =~ m/Number\s+of\s+NACPs/) {
        last;
    }

  }

# print out everything
#  for ($ail=0; $ail<@ails; $ail++) {
#    print "AIL $ail\n";
#    print "$ails[$ail]\t$props[$ail]\t$cps[$ail]\n";
#    print "Critical Point Indices\n";
#    foreach($cps[$ail]) {
#      foreach(@{$_}) {
#        print "@{$_}\n";
#      }
#    }
#    print "Cartesian Coordinates\n";
#    foreach($ails[$ail]) { # 24 of these
#      foreach(@{$_}) {     # iterate over both gradient paths
#        foreach(@{$_}) {
#          print "@{$_}\n";
#        } print "\n";
#      }
#    }
#    print "Property Hashmaps\n";
#    foreach($props[$ail]) { # each is an array ref
#      foreach (@{$_}) { # 2 array references
#        foreach(@{$_}) {
#          print "$_\n"; # hash reference
#          for $property (keys %{$_}) {
#            print "$property ${$_}{$property}\n";
#          }
#
#        } print "\n";
#      }
#    }
#  }

  return \@ails, \@cps, \@props;

}

sub parseGradientPath {

  my @points = ();
  my @props  = ();

  foreach(@{$_[0]}) {

    if ($_ =~ m/\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
      if ($4 >= 0.001) {
        my @coords = ($1,$2,$3);
        push(@points,\@coords);

        my %map; $map{'rho'} = $4;
        push(@props,\%map);
      }
    } else {
      die "Malformed line: $_\n";
    }

  }
  return \@points, \@props;

}

sub parseRelatedIasvizFiles {

  @elements = @{$_[0]};
  @indices  = @{$_[1]};
  $sysName  = "$_[2]";

  my @atomic_surface_coords;
  my @atomic_surface_properties;
  my @atomic_surface_indices;

  my @envelope_coords;
  my @envelope_properties;
  my @envelope_indices;

  my @atomic_basin_coords;
  my @atomic_basin_properties;
  my @atomic_basin_indices;

  $iasvizDir = "$sysName\_atomicfiles";
  for($i=0; $i<@indices; $i++) {
    
    $element = lc($elements[$i]);
    $iasvizFile = "$iasvizDir\/$element$indices[$i]\.iasviz";
    $basvizFile = "$iasvizDir\/$element$indices[$i]\.basviz";
    if (-e $iasvizFile) {

      $iasvizContents = readFile($iasvizFile);

      $atom = parseAtomFromIasviz($iasvizContents);
      $atom =~ m/[a-zA-Z]+(\d+)/; $cp_index = $1;
      ($as_coords, $as_properties) = parseAtomicSurfaceFromIasviz($iasvizContents);
      push(@atomic_surface_coords,$as_coords);
      push(@atomic_surface_properties,$as_properties);
      push(@atomic_surface_indices,$cp_index);

      ($coords, $properties) = parseIntegrationRayIsodensitySurfaceIntersectionsFromIasviz($iasvizContents);
      push(@envelope_coords,$coords);
      push(@envelope_properties,$properties);
      push(@envelope_indices,$cp_index);

    } else {
      print STDERR "Warning\: No iasviz file found for $element$indices[$i]\n";
    }

    if (-e $basvizFile) {

      $basvizContents = readFile($basvizFile);

      $atom = parseAtomFromIasviz($basvizContents);
      $atom =~ m/[a-zA-Z]+(\d+)/; $cp_index = $1;
      ($basin_coords,$basin_properties) = parseBasinFromBasviz($basvizContents);
      push(@atomic_basin_coords,$basin_coords);
      push(@atomic_basin_properties,$basin_properties);
      push(@atomic_basin_indices,$cp_index);

    } else {
      print STDERR "Warning\: No basviz file found for $element$indices[$i]\n";
    }

  }

  return \@atomic_surface_coords, 
         \@atomic_surface_properties,
         \@atomic_surface_indices,
         \@envelope_coords, 
         \@envelope_properties,
         \@envelope_indices,
         \@atomic_basin_coords,
         \@atomic_basin_properties,
         \@atomic_basin_indices;
}

sub parseBasinFromBasviz {

  my @basvizContents = @{$_[0]};

  my @basin_coords;
  my @basin_properties;

  foreach($line=0; $line<@basvizContents; $line++) {
    if ($basvizContents[$line] =~ m/\<Basin\s+Path\>/) {
      if ($basvizContents[$line+1] =~ m/(\d+)\s+\d+\s+-?\d+\.\d+E[+-]\d+/) {
        $nPoints = $1;
      } else {
        die "Malformed header of Basin Path\: $basvizContents[$line+1]\n\n";
      }

      @slice = @basvizContents[$line+2..$line+1+$nPoints];
      ($gp_coords, $gp_properties) = parseGradientPath(\@slice);
      push(@basin_coords,$gp_coords);
      push(@basin_properties,$gp_properties);

    }
  }

  return \@basin_coords, \@basin_properties;

}

sub parseAtomFromIasviz {

  my @fileContents = @{$_[0]};
  for ($line=0; $line<@fileContents; $line++) {
    if ($fileContents[$line] =~ m/\<Atom\>/) {
      if ($fileContents[$line+1] =~ m/(\w+\d+)/) {
        return $1;
      } else {
        die "Malformed line parsing Atom\: $fileContents[$line+1]\n";
      }
    }
  }

}

sub parseAtomicSurfaceFromIasviz {

  # this will parse a complete iasviz file so must return an atomic surface
  # made up of one or more interatomic surfaces

  my @fileContents = @{$_[0]};

  my @as_coords;
  my @as_properties;

  my @ias_coords     = ();
  my @ias_properties = ();

  $currentIndex = -1;
  for($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/\<IAS Path\>/) {

      if ($fileContents[$line+1] =~ m/(\d+)\s+(\d+)\s+(-?\d+\.\d+E[-+]\d+)/) {
        $ias_index = $1; # index of the IAS in this atomic surface - check if new
        $nPoints   = $2; # number of points on this path

        if ($ias_index != $currentIndex) {

          if ($currentIndex != -1) {

            my @keep_coords     = @ias_coords;
            my @keep_properties = @ias_properties;
             
            push(@as_coords,\@keep_coords);
            push(@as_properties,\@keep_properties);

          }

          @ias_coords     = ();
          @ias_properties = ();
          $currentIndex = $ias_index;

        }

      } else {
        die "Malformed header of IAS Path\: $fileContents[$line+1]\n";
      }

      # make an array slice and pass to the parseGradientPath
      my @slice = @fileContents[$line+2 .. $line+1+$nPoints];
      ($gp_coords, $gp_properties) = parseGradientPath(\@slice);

      push(@ias_coords,$gp_coords);
      push(@ias_properties,$gp_properties);

    } elsif ($fileContents[$line] =~ m/\<\/IAS Path\>/) {

    }
  }

  my @keep_coords = @ias_coords;
  my @keep_properties = @ias_properties;
  push(@as_coords,\@keep_coords);
  push(@as_properties,\@keep_properties);

#  $ref = \@as_coords;
#  print STDERR "Atomic Surface Array\: $ref\n";
#  foreach(@as_coords) {
#    print STDERR "Interatomic Surface Array\: $_\t";
#    $n = scalar(@{$_}); print STDERR "N = $n\n";
#    foreach(@{$_}) {
      #print STDERR "IAS Path Array\: $_\t";
      #$n = scalar(@{$_}); print STDERR "N = $n\n";
#      foreach(@{$_}) {
        #print STDERR "Position Vector Array\: $_ @{$_}\n";
#      }
#    }
#  }
#  print STDERR "\n";

  return \@as_coords, \@as_properties;

}

sub parseIntegrationRayIsodensitySurfaceIntersectionsFromIasviz {

  @vizContents = @{$_[0]};

  my @points;
  my @props;

  for ($line=0; $line<@vizContents; $line++) {

    if ($vizContents[$line] =~ m/\<Intersections of Integration Rays With IsoDensity Surfaces\>/) {

      if ($vizContents[$line+1] =~ m/(\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(\d+)/) {
        $isovalue = $3;
        $nLines = $5;
      } else {
        die "Malformed line in ray-isosurface intersection\n\: $vizContents[$line+1]\n";
      }

      for ($point=$line+2;$point<$line+2+$nLines; $point++) {
        if ($vizContents[$point] =~ m/(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)/) {
          my @coords = ($1, $2, $3);

          push(@points,\@coords);
          my %map; $map{'rho'} = $isovalue;
          push(@props,\%map);
        } else {
          die "Malformed line\: $vizContents[$point]\n";
        }
      }
      return \@points, \@props;
    }
  }

}

sub determineRings {
  print "to be implemented\n";
}

sub determineCages {
  print "to be implemented\n";
}

