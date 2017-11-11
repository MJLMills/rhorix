# WriteTopology Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for tasks related to writing XML files adherent to the Topology.dtd document model

package WriteTopology;
require Exporter;
use XmlRoutines qw(writePCData openTag closeTag writeXMLHeader);

### Module Settings ###

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(writeTopologyXML);
our $VERSION = 1.0;

### Subroutines ###

# writeTopologyXML - Write a Topology XML file
# Arguments: $_[0] - String with path to DTD file (XML requirement - not part of definition of topology)
#            $_[1] - String variable - name of the chemical system
#            $_[2] - Reference to array of SourceInformation data
#            Nuclei Data
#            $_[3] - Reference to array of String nuclear elements
#            $_[4] - Reference to array of Integer nuclear indices
#            $_[5] - Reference to array of references to 3-arrays of Reals (Nuclear Cartesian coordinates)
#            Critical Point Data
#            $_[6] - 
#            $_[7] - 
#            $_[8] - 
#            $_[9] - 
#            $_[10] - 
#            Gradient Vector Field Data
#              Molecular Graph Data
#              $_[11]
#              $_[12]
#              $_[13]
#              Atomic Surface Data
#              $_[14]
#              $_[15]
#              $_[16]
#              Atomic Surface Triangulation Data
#              $_[17] - coords of points in each surface
#              $_[18] - properties measured at points in each surface
#              $_[19] - edges connecting points of each surface
#              $_[20] - faces connecting points of each surface
#              Ring Surface Data
#              $_[21] - reference to array of arrays, each being an array of 3-length arrays of cartesians
#              $_[22] - reference to array of arrays, each being an array of 2 indices
#              $_[23] - reference to array of arrays, each being an array of dicts
#              Envelope Data
#              $_[24] - reference to an array of arrays, each being an array of 3-length arrays (points on the envelope)
#              $_[25] - dicts as above
#              $_[26] - NACP indices for envelopes
#              Envelope Triangulation Data
#              $_[27] - edges connecting points of each envelope
#              $_[28] - faces connecting points of each envelope
#              Atomic Basin Data
#              $_[29]
#              $_[30]
#              $_[31]
#              RingData - not supported
#              CageData - not supported

sub writeTopologyXML {

  writeXMLHeader("1.0","UTF-8","Topology",$_[0]);

  openTag("Topology");
  writePCData("SystemName",$_[1]);
  writeSourceInformation($_[2]);
  writeNuclei($_[3],$_[4],$_[5]);
  writeCriticalPoints($_[6],$_[7],$_[8],$_[9],$_[10]);
  writeGradientVectorField($_[11],$_[12],$_[13],$_[14],$_[15],$_[16],$_[17],$_[18],$_[19],$_[20],$_[21],$_[22],$_[23],$_[24],$_[25],$_[26],$_[27],$_[28],$_[29],$_[30],$_[31]);

  closeTag("Topology");

}

# writeSourceInformation - Write a SourceInformation XML element (4 strings)
# Arguments: $_[0] - name of QM code used for wavefunction
#            $_[1] - name of QM method used for wavefunction
#            $_[2] - name of basis set in which wavefunction is expanded
#            $_[3] - name of QCT software used for topology calculation
sub writeSourceInformation {

  @info = @{$_[0]};

  openTag("SourceInformation");
    writePCData("quantum_software" ,$info[0]);
    writePCData("quantum_method"   ,$info[1]);
    writePCData("basis_set"        ,$info[2]);
    writePCData("analysis_software",$info[3]);
  closeTag("SourceInformation");

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

  for ($i=0; $i<@cpIndices; $i++) {
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

# writeGradientVectorField - Write a GradientVectorField XML element
# Arguments
#              Molecular Graph Data
#              $_[0]
#              $_[1]
#              $_[2]
#              Atomic Surface Data
#              $_[3]
#              $_[4]
#              $_[5]
#              Atomic Surface Triangulation Data
#              $_[6] - coords of points in each surface
#              $_[7] - properties measured at points in each surface
#              $_[8] - edges connecting points of each surface
#              $_[9] - faces connecting points of each surface
#              Ring Surface Data
#              $_[10] - reference to array of arrays, each being an array of 3-length arrays of cartesians
#              $_[11] - reference to array of arrays, each being an array of 2 indices
#              $_[12] - reference to array of arrays, each being an array of dicts
#              Envelope Data
#              $_[13] - reference to an array of arrays, each being an array of 3-length arrays (points on the envelope)
#              $_[14] - dicts as above
#              $_[15] - NACP indices for envelopes
#              Envelope Triangulation Data
#              $_[16] - edges connecting points of each envelope
#              $_[17] - faces connecting points of each envelope
#              Atomic Basin Data
#              $_[18]
#              $_[19]
#              $_[20]

sub writeGradientVectorField {

  openTag("GradientVectorField");
    writeMolecularGraph($_[0],$_[1],$_[2]);
    writeAtomicBasins($_[18],$_[19],$_[20]);
#    writeEnvelopes($_[13],$_[14],$_[15],$_[16],$_[17]);
    writeAtomicSurfaces($_[3],$_[4],$_[5],$_[6],$_[7],$_[8],$_[9]);
    writeRingSurfaces($_[10],$_[11],$_[12]);
    #writeRings() # not supported
    #writeCages() # not supported
  closeTag("GradientVectorField");

}

# writeMolecularGraph - Write a MolecularGraph XML element (list of AILS)
# Arguments: $_[0] - 
sub writeMolecularGraph {

  @ails       = @{$_[0]};
  @cps        = @{$_[1]};
  @props      = @{$_[2]};

  openTag("MolecularGraph");

    for($ail=0; $ail<@ails; $ail++) {
      writeAtomicInteractionLine($cps[$ail],$ails[$ail],$props[$ail]);
    }

  closeTag("MolecularGraph");

}

sub writeAtomicSurfaces {

  # For each Atomic Surface,  
  @as_coords     = @{$_[0]}; # gradient path coordinates of each IAS in that atomic surface
  @as_properties = @{$_[1]}; # gradient path properties of each IAS in that atomic surface
  @as_indices    = @{$_[2]}; # index of the nuclear attractor critical point enclosed by that atomic surface 
  @triang_coords = @{$_[3]}; # coordinates of points included in the triangulation of each IAS in that atomic surface
  @triang_props  = @{$_[4]}; # properties of points included in the triangulation of each IAS in that atomic surface
  @triang_edges  = @{$_[5]}; # edges between points included in the triangulation of each IAS in that atomic surface
  @triang_faces  = @{$_[6]}; # faces between points included in the triangulation of each IAS in that atomic surface

  for ($as=0; $as<@triang_coords; $as++) {

    openTag("AtomicSurface");

    @ias_coords = @{$triang_coords[$as]};
    @ias_props  = @{$triang_props[$as]};
    @ias_edges  = @{$triang_edges[$as]};
    @ias_faces  = @{$triang_faces[$as]};

    for($ias=0; $ias<@ias_coords; $ias++) {
      openTag("InteratomicSurface");
      writeTriangulation($ias_coords[$ias],$ias_props[$ias],$ias_edges[$ias],$ias_faces[$ias]);
      closeTag("InteratomicSurface");
    }

    closeTag("AtomicSurface");

  }

}

# writeAtomicSurface - Write an AtomicSurface XML element
# Arguments: $_[0] - Integer index of corresponding NACP
#            $_[1] - Reference to an array of GradientPaths in the IAS
#            $_[2] - Reference to array of 3-vectors of triangulated reals
#            $_[3] - Reference to array of 3-vectors of Integers (faces)
#            $_[4] - Reference to array of 2-vectors of Integers (edges)
sub writeAtomicSurface {

  @ias_coords     = @{$_[0]};
  @ias_properties = @{$_[1]};
  $ias_cp_index   = $_[2];
  $triang_coords  = $_[3];
  $triang_props   = $_[4];
  $triang_edges   = $_[5];
  $triang_faces   = $_[6];

  #print STDERR "Critical Point Index\: $ias_cp_index\n";
  #$niasCoords     = @ias_coords;     print STDERR "Num. IASs in Atomic Surface\: $niasCoords\n\n";
  #$niasProperties = @ias_properties; #print STDERR "Num. IASs in Atomic Surface\(props\)\: $niasProperties\n";

  openTag("AtomicSurface");
    for ($ias=0; $ias<@ias_coords; $ias++) {
      writeInteratomicSurface($ias_coords[$ias],$ias_properties[$ias],$ias_cp_index,$triang_coords,$triang_props,$triang_edges,$triang_faces);
    }
  closeTag("AtomicSurface");

}

# writeIAS - Write an InteratomicSurface XML element
# Arguments: $_[0] - Reference to array of GradientPaths in the IAS
#            $_[1] - Reference to array of 3-vectors of triangulated reals
#            $_[2] - Reference to array of 3-vectors of Integers (faces)
#            $_[3] - Reference to array of 2-vectors of Integers (edges)
sub writeInteratomicSurface {

  #print STDERR "IAS Array Ref\: $_[0]\n";
  @gp_coords     = @{$_[0]};
  @gp_properties = @{$_[1]};
  $gp_cp_index   = $_[2];
  $triangulation_coords     = $_[3];
  $triangulation_properties = $_[4];
  $triangulation_edges      = $_[5];
  $triangulation_faces      = $_[6];

  #$nlfCoords     = @gp_coords;     print STDERR "Num. Paths in IAS \: $nlfCoords\n";
  #$nProperties   = @gp_properties; print STDERR "Num. Paths in IAS \(props\)\: $nProperties\n";

  openTag("InteratomicSurface");

    for ($gp=0; $gp<@gp_coords; $gp++) {
      writeGradientPath($gp_cp_index,0,$gp_coords[$gp],$gp_properties[$gp]);
    }
    
    writeTriangulation($triangulation_coords,$triangulation_properties,$triangulation_edges,$triangulation_faces);

  closeTag("InteratomicSurface");

}

# writeEnvelopes - Write a set of Envelope XML elements
# Arguments: $_[0] - Reference to an array of Envelopes
sub writeEnvelopes {

  @coords = @{$_[0]};
  @properties = @{$_[1]};
  @indices = @{$_[2]};
  @triang_edges  = @{$_[3]};
  @triang_faces  = @{$_[4]};

  for ($envelope=0; $envelope<@coords; $envelope++) {
    writeEnvelope(0.001,$indices[$envelope],$coords[$envelope],$properties[$envelope]);
  }

}

# writeEnvelope - Write an Envelope XML element
# Arguments: $_[0] - electron density isovalue (real,au)
#            $_[1] - Integer index of corresponding NACP
#            $_[2] - Reference to array of PositionVectors of points on the surface (which may be triangulated)
#            $_[3] - Reference to properties of surface points
#            $_[4] - Reference to array of edges between surface points
#            $_[5] - Reference to array of faces between triplets of surface points
sub writeEnvelope {

  openTag("Envelope");
    writePCData("isovalue",$_[0]);
    writePCData("cp_index",$_[1]);
    writeTriangulation($_[2],$_[3],$_[4],$_[5]);
  closeTag("Envelope");

}

sub writeAtomicBasins {

  @ab_coords     = @{$_[0]};
  @ab_properties = @{$_[1]};
  @ab_indices    = @{$_[2]};

  for ($ab=0; $ab<@ab_coords; $ab++) {
    writeAtomicBasin($ab_coords[$ab],$ab_properties[$ab],$ab_indices[$ab]);
  }

}

# writeAtomicBasin - Write an AtomicBasin XML element
# Arguments: $_[0] - Reference to array of gradient paths in the basin
sub writeAtomicBasin {

  @gp_coords     = @{$_[0]};
  @gp_properties = @{$_[1]};
  $cp_index      = $_[2];

  openTag("AtomicBasin");
    for ($gp=0; $gp<@gp_coords; $gp++) {
      writeGradientPath($cp_index,0,$gp_coords[$gp],$gp_properties[$gp]);
    }
  closeTag("AtomicBasin");

}

sub writeRingSurfaces {

  my @coords     = @{$_[0]};
  my @indices    = @{$_[1]};
  my @properties = @{$_[2]};

  for($ring_surface=0; $ring_surface<@coords; $ring_surface++) {
    writeRingSurface($coords[$ring_surface],$indices[$ring_surface],$properties[$ring_surface]);
  }

}

# writeRingSurface - Write a RingSurface XML element
# Arguments: $_[0] - Reference to array of reference to arrays of 3-arrays of Reals
sub writeRingSurface {

  my @coords = @{$_[0]};
  my @indices = @{$_[1]};
  my @properties = @{$_[2]};

  openTag("RingSurface");
    for ($gp=0; $gp<@coords; $gp++) {
      $cp_a = @{$indices[$gp]}[0];
      $cp_b = @{$indices[$gp]}[1];
      writeGradientPath($cp_a,$cp_b,$coords[$gp],$properties[$gp]);
    }
  closeTag("RingSurface");

}

# writeRing - Write a Ring XML Element (list of AILs)
sub writeRing {

  print STDERR "writeRing: To be implemented\n";
  #openTag("Ring");
  #closeTag("Ring");

}

# writeCage - Write a Cage XML Element (list of Rings)
sub writeCage {

  print STDERR ("writeCage: To be implemented\n");
  #openTag("Cage");
  #closeTag("Cage");

}

# writeTriangulation - Write a Triangulation XML element
# Arguments: $_[0] - Reference to an array of 3-arrays of Reals (Cartesian coordinates)
#            $_[1] - Reference to an array of 3-arrays of Integers (faces)
#            $_[2] - Reference to an array of 2-arrays of Integers (edges)
sub writeTriangulation {

  my @coords     = @{$_[0]}; # vector of 3-vectors of coordinates
  my @properties = @{$_[1]}; # vector of dicts of scalar properties
  my @edges      = @{$_[2]}; # vector of 2 indices in each edge
  my @faces      = @{$_[3]}; # vector of 3 indices in each face

  openTag("Triangulation");
    for($point=0; $point<@coords; $point++) {
      writePoint($coords[$point],$properties[$point]);
    }
    foreach(@{$_[2]}) {
      writeEdge($_);
    }
    foreach(@{$_[3]}) {
      writeFace($_);
    }
  closeTag("Triangulation");

}

# writeEdge - Write an Edge XML element
# Arguments: $_[0] - Reference to a 2-vector of Integers
sub writeEdge {

  @indices = @{$_[0]};

  openTag("Edge");
    writePCData("edge_a",$indices[0]);
    writePCData("edge_b",$indices[1]);
  closeTag("Edge");

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

# writeAtomicInteractionLine - Write an AtomicInteractionLine XML element
sub writeAtomicInteractionLine {

  openTag("AtomicInteractionLine");

    @indices        = @{$_[0]};
    @gradient_paths = @{$_[1]};
    @properties     = @{$_[2]};

    for ($gp=0; $gp<@indices; $gp++) {
      $cp_a = @{$indices[$gp]}[0];
      $cp_b = @{$indices[$gp]}[1];
      writeGradientPath($cp_a,$cp_b,$gradient_paths[$gp],$properties[$gp]); # cp_a, cp_b, ref_coords, ref_maps
    }

  closeTag("AtomicInteractionLine");

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

  $cp_a        = $_[0];
  $cp_b        = $_[1];
  @coordinates = @{$_[2]};
  @maps        = @{$_[3]};

  openTag("GradientPath");

    writePCData("cp_index",$cp_a);
    writePCData("cp_index",$cp_b);
    for ($point=0; $point<@coordinates; $point++) {
      writePoint($coordinates[$point],$maps[$point]);
    }

  closeTag("GradientPath");

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

# writePositionVector - Write a PositionVector XML element
# Arguments: $_[0] - Reference to 3-array of reals (Cartesian coordinates)
sub writePositionVector {

  openTag("PositionVector");
    writePCData("x",@{$_[0]}[0]);
    writePCData("y",@{$_[0]}[1]);
    writePCData("z",@{$_[0]}[2]);
  closeTag("PositionVector");  

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

# writePair - Write a Pair XML element
# Argument: $_[0] - String key of property
#           $_[1] - Real value of property
sub writePair {

  openTag("Pair");
    writePCData("key",$_[0]);
    writePCData("value",$_[1]);
  closeTag("Pair");

}
