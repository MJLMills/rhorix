#!/usr/bin/perl
# Matthew J L Mills - Perl library for writing XML files adherent to the Topology.dtd document model
# This file is part of Rhorix 1.0, June 22, 2017

sub writeTopologyXML {

  writeXMLHeader("1.0","UTF-8","Topology","/Users/mjmills/Desktop/Topology.dtd");

  openTag("Topology");
  writePCData("SystemName",$_[0]);
  writeNuclei($_[1],$_[2],$_[3]);
  writeCriticalPoints($_[4],$_[5],$_[6],$_[7],$_[8]);
  #writeGradientVectorField(); WHICH SHOULD INCLUDE THE BELOW ROUTINES

  #writeGradientPaths;
  #writeSurfaces;

  closeTag("Topology");

}

# writePositionVector - Write a PositionVector XML element
# Arguments: $_[0] - Reference to 3-array of reals (Cartesian coordinates)
sub writePositionVector {

  openTag("PositionVector");
    writePCData("x",@{$_[0]}[0]);
    writePCData("y",@{$_[0]}[1]);
    writePCData("z",@{$_[0]}[2]);
  closeTag("PositionVector");  

}

# writePair - Write a Pair XML element
# Argument: $_[0] - String key of property
#           $_[1] - Real value of property
sub writePair {

  openTag("Pair");
    writePCData("key",$_[0]);
    writePCData("value",$_[1]);
  closeTag("Pair");

}

# writeMap - Write a Map XML element
# Arguments: $_[0] - Reference to a Map from String names to Real values
sub writeMap {

  openTag("Map");
  for $property (keys %{$_[0]}) {
    writePair($property,${$_[0]}{$property});
  }
  closeTag("Map");

}

# writePoint - Write a Point XML element
# Arguments: $_[0] - Reference to 3-array of reals (Cartesian coordinates)
#            $_[1] - Reference to Map from String keys to Real values
sub writePoint {

  openTag("Point");
    writePositionVector($_[0]);
    writeMap($_[1]);
  closeTag("Point");

}

# writeNuclei - Write a Nuclei XML element
# Arguments: $_[0] - Reference to array of String nuclear elements
#            $_[1] - Reference to array of Integer nuclear indices
#            $_[2] - Reference to array of references to 3-arrays of Reals (Cartesian coordinates)
sub writeNuclei {

  @elements         = @{$_[0]};
  @nucleus_indices  = @{$_[1]};
  @position_vectors = @{$_[2]};

  openTag("Nuclei");
  for($i=0; $i<@elements; $i++) {
    writeNucleus($elements[$i],$nucleus_indices[$i],$position_vectors[$i]);
  }
  closeTag("Nuclei");

}

# writeNucleus - Write a Nucleus XML element
# Arguments: $_[0] - String chemical element of nucleus
#            $_[1] - Integer index of nucleus
#            $_[2] - Reference to 3-array of Reals (Cartesian coordinates)
sub writeNucleus {

  openTag("Nucleus");
    writePCData("element",$_[0]);
    writePCData("nucleus_index",$_[1]);
    writePositionVector($_[2]);
  closeTag("Nucleus");

}

# writeCriticalPoints - Write a set of CriticalPoint XML elements
# Arguments: $_[0] - Reference to array of Integer CP indices
#            $_[1] - Reference to array of Integer CP ranks
#            $_[2] - Reference to array of Integer CP signatures
#            $_[3] - Reference to array of references to 3-arrays of Reals (Cartesian coordinates)
#            $_[4] - Reference to array of references to String -> Real Maps (scalar properties)
sub writeCriticalPoints {

  @cpIndices        = @{$_[0]};
  @ranks            = @{$_[1]};
  @signatures       = @{$_[2]};
  @cpCoordinates    = @{$_[3]};
  @scalarProperties = @{$_[4]};

  for ($i=0; $i<@indices; $i++) {
    writeCP($cpIndices[$i],$ranks[$i],$signatures[$i],$cpCoordinates[$i],$scalarProperties[$i]);
  }

}

# writeCP - Write a CriticalPoint XML element
# Arguments: $_[0] - Integer index of critical point
#            $_[1] - Integer rank of critical point
#            $_[2] - Integer signature of critical point
#            $_[3] - Reference to 3-array of real values (Cartesian coordinates)
#            $_[4] - Reference to Map from String keys to Real values
sub writeCP {

  openTag("CriticalPoint");
    writePCData("cp_index",$_[0]);
    writePCData("rank",$_[1]);
    writePCData("signature",$_[2]);
    writePoint($_[3],$_[4]);
  closeTag("CriticalPoint");

}

# writeGradientPaths - Write a set of GradientPath XML elements
# Arguments: $_[0] - Reference to array with Integer indices of first endpoints
#            $_[1] - Reference to array with Integer indices of second endpoints
#            $_[2] - Reference to array of references to 3-arrays of Real values (Cartesian coordinates)
#            $_[3] - Reference to array of references to Map from String keys to Real values
sub writeGradientPaths {

  @a_indices = @{$_[0]};
  @b_indices = @{$_[1]};
  @coords    = @{$_[2]};
  @maps      = @{$_[3]}; 

  for ($path=0; $path<@coords; $path++) {
    writeGradientPath($a_indices[$path],$b_indices[$path],$coords[$path],$maps[$path]);
  }

}

# writeGradientPath - Write a GradientPath XML element
# Arguments: $_[0] - Integer cp_index of first endpoint
#            $_[1] - Integer cp_index of second endpoint
#            $_[2] - Reference to array of references to 3-arrays of reals (Cartesian coordinates)
#            $_[3] - Reference to map of String keys to Real values
sub writeGradientPath {

  @coordinates = @{$_[2]};
  @maps = @{$_[3]};

  openTag("GradientPath");
    writePCData("cp_index",$_[0]);
    writePCData("cp_index",$_[1]);
    for ($point=0; $point<@coordinates; $point++) {
      writePoint($coordinates[$point],$maps[$point]);
    }
  closeTag("GradientPath");

}

# writeIASs - Write a set of InteratomicSurface XML elements
# Arguments: $_[0] - Reference to array of InteratomicSurfaces of the GradientVectorField
sub writeIASs {

  foreach(@{$_[0]}) {
    writeIAS($_);
  }

}

# writeFace - Write a Face XML element
# Arguments: $_[0] - Reference to a 3-vector of Integers
sub writeFace {

  @indices = @{$_[0]};

  openTag("Face");
    writePCData("face_a",$indices[0]);
    writePCData("face_b",$indices[1]);
    writePCData("face_c",$indices[2]);
  closeTag("Face");

}

# writeEdge - Write an Edge XML element
# Arguments: $_[0] - Reference to a 2-vector of Integers
sub writeEdge {

  @indices = @{$_[0]};

  openTag("Edge");
    writePCData("edge_a",$indices[0]);
    writePCData("edge_b",$indices[1]);
  cloeTag("Edge");

}

# writeTriangulation - Write a Triangulation XML element
# Arguments: $_[0] - Reference to an array of 3-arrays of Reals (Cartesian coordinates)
#            $_[1] - Reference to an array of 3-arrays of Integers (faces)
#            $_[2] - Reference to an array of 2-arrays of Integers (edges)
sub writeTriangulation {

  openTag("Triangulation");
    foreach(@{$_[0]}) {
      writePositionVector($_);
    }
    foreach(@{$_[1]}) {
      writeFace($_);
    }
    foreach(@{$_[2]}) {
      writeEdge($_);
    }
  closeTag("Triangulation");

}

# writeIAS - Write an InteratomicSurface XML element
# Arguments: $_[0] - Reference to array of GradientPaths in the IAS
#            $_[1] - Reference to array of 3-vectors of triangulated reals
#            $_[2] - Reference to array of 3-vectors of Integers (faces)
#            $_[3] - Reference to array of 2-vectors of Integers (edges)
sub writeIAS {

  openTag("InteratomicSurface");
    foreach(@{$_[0]}) {
      writeGradientPath($_);
    }
    writeTriangulation($_[1],$_[2],$_[3]);
  closeTag("InteratomicSurface");

}

# writeAtomicSurface - Write an AtomicSurface XML element
# Arguments: $_[0] - Integer index of corresponding NACP
#            $_[1] - Reference to an array of GradientPaths in the IAS
#            $_[2] - Reference to array of 3-vectors of triangulated reals
#            $_[3] - Reference to array of 3-vectors of Integers (faces)
#            $_[4] - Reference to array of 2-vectors of Integers (edges)
sub writeAtomicSurface {

  openTag("AtomicSurface");
    writePCData("cp_index",$_[0]);
    foreach(@{$_[1]}) {
      writeIAS($_[1],$_[2],$_[3],$_[4]);
    }
  closeTag("AtomicSurface");

}

# writeEnvelopes - Write a set of Envelope XML elements
# Arguments: $_[0] - Reference to an array of Envelopes
sub writeEnvelopes {

  foreach(@{$_[0]}) {
    writeEnvelope($_);
  }

}

# writeEnvelope - Write an Envelope XML element
# Arguments: $_[0] - electron density isovalue (real,au)
#            $_[1] - Integer index of corresponding NACP
#            $_[2] - Reference to array of PositionVectors of points on the surface
sub writeEnvelope {

  openTag("Envelope");
    writePCData("isovalue",$_[0]);
    writePCData("cp_index",$_[1]);
    foreach(@{$_[2]}) {
      writePoint($_);
    }
  closeTag("Envelope");

}

sub writeRingSurface {

}

sub writeAtomicBasin {

}

sub writeAtomicInteractionLine {

}

sub writeMolecularGraph {

}

