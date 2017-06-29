# ParseViz Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseViz;
require Exporter;
use Utilities qw(readFile);

### Module Settings ###

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(parseMgpviz);
our $VERSION = 1.0;

### Subroutines ###


sub parseMgpviz {

  # First read the data about the nuclei - elements, unique indices and Cartesian coordinates of each nucleus
  ($elements,$nuclearIndices,$nuclearCoordinates) = parseNucleiFromViz($_[0]);

  # With the nuclei known, read the critical point data (index, rank, signature, position vector and scalar properties at each CP)
  ($cpIndices,$ranks,$signatures,$cpCoordinates,$scalarProperties) = parseCPsFromViz($_[0]);

  # then parse the gradient vector field from the file
  # Read the gradient paths associated with CPs
#  ($paths,$index_a,$index_b) = parseGradientPathsFromViz($_[0]);

  ($IASs,$envelopes) = parseRelatedIasvizFiles($elements,$nuclearIndices,$_[1]);

  return $elements,
         $nuclearIndices,
         $nuclearCoordinates,
         $cpIndices,
         $ranks,
         $signatures,
         $cpCoordinates,
         $scalarProperties;

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
    } elsif (($parseNuclei == 1) && ($fileContents[$line] =~ m/(\w+)(\d+)\s+\d+\.\d+\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/)) {

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

      if ($fileContents[$line+1] =~ m/Type\s+\=\s+\((-?\d+)\,(-?\d+)\)/) {
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

sub parseGradientPathsFromViz {

  # BCPs:
  #             \d+\s+sample points along path from BCP to atom\s+(\w+\d+) (member 1 of AIL object)
  #             \d+\s+sample points along IAS\s+[+-]EV[12]\s+path from BCP (4 single GPs of IAS)
  # RCPs
  #             \d+\s+sample points along path from RCP to BCP between atoms \w+\d+ and \w+\d+ (path in the ring surface)
  #             \d+\s+sample points along \w+ RCP attractor path (2 ring axes)
  # NACPs do not have paths reported
  # CCPs  do not have paths reported

  @fileContents = @{$_[0]};

  my @paths = ();
  my @indices_a = ();
  my @indices_b = ();

  for($line=0; $line<@fileContents; $line++) {

    # keep track of the current CP
    if ($fileContents[$line] =~ m/CP\#\s+(\d+)/) {
      $cpIndex = $1;
    }

    # at a BCP there are 3 eigenvectors which can each be followed in 2 directions
    # one of these eigenvectors (the +ve eigenvalue'd one) gives components of AILs

    if ($fileContents[$line] =~ m/(\d+)\s+sample points along path from BCP to atom\s+\w+(\d+)/) {

      # The nuclear index can be used to get the index of the NACP coinciding with it

      $nPoints = $1;
      $points = parseGradientPath(\@fileContents[$line+1..$line+1+$nPoints]);
      push(@paths,$points);
      push(@indices_a,$cpIndex);
      push(@indices_b,$2);

    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along IAS\s+[+-]EV[12]\s+path from BCP/) {

      # the BCP is known from context, other CP is Inf

      $nPoints = $1;
      $points = parseGradientPath(\@fileContents[$line+1..$line+1+$nPoints]);
      push(@paths,$points);
      push(@indices_a,$cpIndex);
      push(@indices_b,0);

    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along path from RCP to BCP between atoms\s+\w+(\d+)\s+and\s+\w+(\d+)/) {

#      $nucleus_a  = $2;
#      $nucleus_b  = $3;
      # the RCP is known from context - BCP can be inferred from the two nuclei

      $nPoints    = $1;
      $points = parseGradientPath(\@fileContents[$line+1..$line+1+$nPoints]);
      push(@paths,$points);
      push(@indices_a,$cpIndex);

    } elsif ($fileContents[$line] =~ m/(\d+)\s+sample points along\s+\w+\s+RCP attractor path/) {

      # the RCP is known from context, other CP is Inf

      $nPoints = $1;
      $points = parseGradientPath(\@fileContents[$line+1..$line+1+$nPoints]);
      push(@paths,$points);
      push(@indices_a,$cpIndex);
      push(@indices_b,0);

    }

  }

  return \@paths, \@indices_a, \@indices_b;

}

sub parseGradientPath {

  my @points = ();
  foreach(@{$_[0]}) {

    if ($fileContents[$point] =~ m/\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
      my @values = ($1,$2,$3,$4);
      push(@points,\@values);
    } else {
      die "Malformed line: $fileContents[$point]\n";
    }

  }
  return \@points

}

sub parseRelatedIasvizFiles {

  @elements = @{$_[0]};
  @indices  = @{$_[1]};
  $sysName  = "$_[2]";

  my @IASs = ();
  my @envelopes = ();

  $iasvizDir = "$sysName\_atomicfiles";
  for($i=0; $i<@indices; $i++) {
    
    $element = lc($elements[$i]);
    $iasvizFile = "$iasvizDir\/$element$indices[$i]\.iasviz";
    if (-e $iasvizFile) {

      $iasvizContents = readFile($iasvizFile);

      $atom = parseAtomFromIasviz($iasvizContents);
      $iasPaths = parseIAS($iasvizContents);
      push(@IASs,$iasPaths);

      $envelope = parseIsodensitySurfaceIntersections($iasvizContents);
      push(@envelopes,$envelope);

    }

  }
  return \@IASs, \@envelopes;

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

sub parseIAS {

  my @fileContents = @{$_[0]};

  my @iasPaths = ();
  for($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/\<IAS Path\>/) {

      if ($fileContents[$line+1] =~ m/(\d+)\s+(\d+)\s+(-?\d+\.\d+E[-+]\d+)/) {
        $nPoints = $2;
      } else {
        die "Malformed header of IAS Path\: $fileContents[$line+1]\n";
      }

      my @path = ();
      for ($point=$line+2; $point<$line+2+$nPoints; $point++) {
        if ($fileContents[$point] =~ m/(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)/) {
          my @values = ($1,$2,$3,$4);
          push(@path,\@values);
        } else {
          die "Malformed line during IAS parsing\: $fileContents[$point]\n";
        }
      }
      push(@iasPaths,\@path);

    }
  }

  return \@iasPaths;

}

sub parseIsodensitySurfaceIntersections {

  @vizContents = @{$_[0]};

  for ($line=0; $line<@vizContents; $line++) {

    if ($vizContents[$line] =~ m/\<Intersections of Integration Rays With IsoDensity Surfaces\>/) {

      if ($vizContents[$line+1] =~ m/(\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(\d+)/) {
        $isovalue = $3;
        $nLines = $5;
      }

      my @points = ();
      for ($point=$line+2;$point<$line+2+$nLines; $point++) {
        if ($vizContents[$point] =~ m/(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)\s+(-?\d+\.\d+E[-+]\d+)/) {
          @coords = ($1, $2, $3);
          push(@points,\@coords);
        }
      }
      return $isovalue,\@points;
    }
  }

}

