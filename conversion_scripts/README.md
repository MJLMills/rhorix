# Conversion Scripts

The included Blender Add-On functions entirely on the existence of topological data formatted into the XML format described in the [paper](https://www.researchgate.net/publication/319407440_Rhorix_An_interface_between_quantum_chemical_topology_and_the_3D_graphics_program_blender).
However, no current topological analysis program provides output in this format.
There is therefore a need for tools which can convert the output of existing programs into the XML format.
Where possible, code for writing the XML files has been abstracted into a set of Perl modules.
The scripts in this directory currently allow conversion from output files produced by AIMAll and IRIS.

## Scripts

mgpviz2top.pl - Script for converting AIMAll output to top format.

mif2top.pl - Script for converting MORPHY/IRIS output to top format.

Currently support for MORPHY's mif filetype is contained in a single script with much redundant code with the modules above.
This needs to be changed.

centerTop.pl - center a topology on the center of mass of its nuclei.

The following scripts are for running the IRIS program and collecting its output into a single file respectively.

runIris.pl - run the various executables that comprise IRIS on a set of wavefunctions.
collateMifs.pl - collect the various mif files produced by IRIS into a single file for conversion.


## General Use Modules

In the following, *italics* indicate that a subroutine is made public by its parent module.

### Utilities.pm
Contains generic utility functions related to reading/writing files and dealing with arguments.

*stripExt* - Remove the extension from a filename.

*getExt* - Get the extension from a filename.

*readFile* - Open and read the contents of a file.

*checkArgs* - Check that the appropriate arguments have been passed to a script.

*listFilesOfType* - Make a list of all files with a given extension in a directory.

### XmlRoutines.pm
Contains routines expressly dedicated to writing to XML files and checking their validity against a document type definition.

*writePCData* - Write a parsed character data XML element.

*openTag* - Write an XML element open tag.

*closeTag* - Write an XML element close tag.

*writeXMLHeader* - Write the header of an XML file.

*checkValidity* - Check an XML file against its specified DTD file.

### WriteTopology.pm
Contains routines for writing files which adhere to the topology document type definition.

*writeTopologyXML* - Write a complete topology file.

writeSourceInformation - Write a complete source information element.

writeNuclei - Write a set of nuclei.

writeNucleus - Write a single Nucleus.

writeCriticalPoints - Write a set of critical points.

writeCP - Write a single critical point.

writeGradientVectorField - Write a complete gradient vector field element.

writeMolecularGraph - Write a complete molecular graph element.

writeAtomicSurfaces - Write a set of atomic surfaces.

writeAtomicSurface - Write a single atomic surface.

writeInteratomicSurface - Write a single interatomic surface.

writeEnvelopes - Write a set of constant electron density envelopes.

writeEnvelope - Write a single constant electron density envelope.

writeAtomicBasins - Write a set of atomic basin elements.

writeAtomicBasin - Write a single atomic basin element.

writeRingSurfaces - Write a set of ring surface elements.

writeRingSurface - Write a single ring surface element.

writeRing - Write a ring element.

writeCage - Write a cage element.

writeTriangulation - Write a triangulation element.

writeEdge - Write an edge element.

writeFace - Write a face element.

writeAtomicInteractionLine - Write an atomic interaction line element.

writeGradientPaths - Write a set of gradient path elements.

writeGradientPath - Write a single gradient path element.

writePoint - Write a single point element.

writePositionVector - Write a single position vector element.

writeMap - Write a single map element.

writePair - Write a single pair element.

### TopUtils.pm

*getRank* - Convert a critical point label to the corresponding integer rank value.

*getSignature* - Convert a critical point label to the corresponding integer signature value.

## Topology Program Specific Modules

### ParseViz.pm
Contains functions for reading from AIMAll's .*viz formats and creating corresponding objects.

*parseMgpviz* - Master routine for parsing contents of an .mgpviz file.

parseRingSurfacesFromMgpviz

parseInteratomicSurfacesFromMgpviz

parseSourceInformationFromViz

parseNucleiFromViz

parseCPsFromViz

parseMolecularGraphFromViz

parseGradientPath

parseRelatedIasvizFiles

parseRingSurfacesFromIasviz

parseBasinFromBasviz

parseAtomFromIasviz

parseAtomicSurfaceFromIasviz

parseIntegrationRayIsodensitySurfaceIntersectionsFromIasviz

determineRings

determineCages

### VizUtils.pm
Contains basic utilities related to AIMAll's .*viz file formats.

*checkMgpvizFile* - Confirm that an .mgpviz file is complete and correct.

checkPoincareHopf - Check that a .viz file does not violate the Poincare-Hopf relationship.

checkCompletion - Check for the presence of a completion statement in a .viz file.
