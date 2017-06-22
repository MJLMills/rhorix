#!/usr/bin/perl -w
# Dr. Matthew J L Mills
# Script to convert plaintext output files from QCT codes to XML format (Topology.dtd)

# The single (mandatory) command line argument is the name of the file to convert.
# Must be mgpviz (set -wsp=true); script checks for corresponding atomic iasviz files (-iaswrite=true).

my $mgpvizFile = &checkArgs(\@ARGV,"mgpviz");
if (getExt($mgpvizFile) ne "mgpviz") { die "Error\: Script requires an mgpviz file"; }

$mgpvizContents = readFile($mgpvizFile);
checkMgpvizFile($mgpvizContents);

$systemName = stripExt($mgpvizFile,"mgpviz");

# Attempt to read data from the mgpviz file
($elements,
$nuclearIndices,
$nuclearCoordinates,
$cpIndices,
$ranks,
$signatures,
$cpCoordinates,
$scalarProperties) = parseMgpviz($mgpvizContents,$systemName);

writeTopologyXML($systemName,
                 $elements,
                 $nuclearIndices,
                 $nuclearCoordinates,
                 $cpIndices,
                 $ranks,
                 $signatures,
                 $cpCoordinates,
                 $scalarProperties);

  #### SUBROUTINES ####

### Viz File Parsing Subroutines ###

sub parseMgpviz {

  # First read the data about the nuclei - elements, unique indices and Cartesian coordinates of each nucleus
  ($elements,$nuclearIndices,$nuclearCoordinates) = parseNucleiFromViz($_[0]);

  # With the nuclei known, read the critical point data (index, rank, signature, position vector and scalar properties at each CP)
  ($cpIndices,$ranks,$signatures,$cpCoordinates,$scalarProperties) = parseCPsFromViz($_[0]);

  # then parse the gradient vector field from the file
  # Read the gradient paths associated with CPs
#  ($paths,$index_a,$index_b) = parseGradientPathsFromViz($_[0]);

  parseRelatedIasvizFiles($elements,$nuclearIndices,$_[1]);

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
    $iasvizContents = readFile($iasvizFile);

    $atom = parseAtomFromIasviz($iasvizContents);
    $iasPaths = parseIAS($iasvizContents);
    push(@IASs,$iasPaths);

    $envelope = parseIsodensitySurfaceIntersections($iasvizContents);
    push(@envelopes,$envelope);

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

### XML File Output Subroutines ###

# writePCData - Write a single parsed character data XML element on a single line
# Arguments: $_[0] - Name of the element
#            $_[1] - Value of the element
sub writePCData {
  print "\<$_[0]\>$_[1]\<\/$_[0]\>\n";
}

# openTag - Write an XML open tag for an element
# Arguments: $_[0] - Name of the element
sub openTag {
  print "\<$_[0]\>\n";
}

# closeTag - Write an XML close tag for an element
# Arguments: $_[0] - Name of the element
sub closeTag {
  print "\<\/$_[0]\>\n";
}

# writeXMLHeader - Write the header of an XML file
# Arguments: $_[0] - XML version number
#            $_[1] - Encoding name
#            $_[2] - Name of root XML tag
#            $_[3] - Path to DTD file
sub writeXMLHeader {

  $version  = $_[0];
  $encoding = $_[1];
  $root     = $_[2];
  $dtdPath  = $_[3];

  print "\<\?xml version\=\"$version\" encoding=\"$encoding\"\?\>\n";
  print "\<\!DOCTYPE $root PUBLIC \"ID\" \"$dtdPath\"\>\n";

}

### Viz File-Specific Subroutines ###

# checkMgpvizFile - Check validity of an mgpviz file
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkMgpvizFile {

  if (checkPoincareHopf($_[0]) == 0) { print "Warning: Poincare-Hopf Relationship Violated\n"; }
  if (checkCompletion($_[0])   == 0) { print "Warning: .mgpviz File Appears Incomplete\n"; }

}

# checkPoincareHopf - Determine whether CPs reported in mgpviz file satisfies the Poincare-Hopf relationship
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkPoincareHopf {

  for ($line=@{$_[0]}-1; $line>=0; $line--) {
    if (${$_[0]}[$line] =~ m/Poincare-Hopf Relationship is Satisfied/) {
      return 1;
    }
  }
  return 0;

}

# checkCompletion - Check for presence of the final line of an mgpviz file
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkCompletion {

  for ($line=@{$_[0]}-1; $line>=0; $line--) {
    if (${$_[0]}[$line] =~ m/Total time for electron density critical point search, analysis and connectivity \=\s+\d+\s+sec \(NProc =\s+\d+\)/) {
      return 1;
    }
  }
  return 0;

}

### General Subroutines ###

# stripExt - Remove the extension from a filename
# Arguments: $_[0] - name of file
# Return: name of file with extension and . removed (characters before '.')
sub stripExt {
  
  if ($_[0] =~ m/(.*)\.$_[1]/) {
    return $1;
  } else {
    die "Error\: Could not strip extension from $_[0]\n";
  }

}

# getExt - Return the extension from a filename
# Arguments: $_[0] - name of file
# Return: extension of file (characters after '.')
sub getExt {

  if ($_[0] =~ m/.*\.(.*)/) {
    return $1;
  } else {
    die "Error\: Could not determine extension of $_[0]\n";
  }

}

# readFile - Open and read the contents of a file to an array
# Arguments: $_[0] - name of file
# Return: Reference to an array of file contents
sub readFile {

  open(INP,"<","$_[0]") || die "Error: Cannot open $_[0] for reading\n";
  @inpContents = <INP>;
  chomp(@inpContents);
  close INP;

  return \@inpContents;

}

# checkArgs - Check the correct number (1) of arguments is passed to the script and return single argument
# Arguments: $_[0] - Reference to an array of script arguments
# Return: name of file (first element of argument array provided only one element present)
sub checkArgs {

  my $nArg = @{$_[0]};
  my $ext = $_[1];
  if ($nArg == 0 || $nArg > 1) {
    die "Error: Incorrect number of arguments \($nArg\)\nPlease run script as \"perl $0 file\.$ext\"\n";
  } else {
    return "@{$_[0]}[0]";
  }

}

