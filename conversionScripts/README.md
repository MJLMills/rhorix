# Conversion Scripts

The included Blender Add-On functions entirely on the existence of topological data formatted into the XML format described in the [paper](https://www.researchgate.net/publication/319407440_Rhorix_An_interface_between_quantum_chemical_topology_and_the_3D_graphics_program_blender).
However, no current topological analysis program provides output in this format.
There is therefore a need for tools which can convert the output of existing programs into the XML format.
Where possible, code for writing the XML files has been abstracted into a set of Perl modules.

#### General Use Modules

Utilities.pm - Contains generic utility functions related to reading/writing files and dealing with arguments.

XmlRoutines.pm - Contains routines expressly dedicated to writing to XML files and checking their validity against a document type definition.

WriteTopology.pm - Contains routines for writing files which adhere to the topology document type definition.


#### Topology Program Specific Modules

ParseViz.pm - Contains functions for reading from AIMAll's .*viz formats and creating corresponding objects.

VizUtils.pm - Contains basic utilities related to AIMAll's .*viz file formats.

mgpviz2top.pl - Script for converting AIMAll output to top format.

#### Other

mif2top.pl - Script for converting MORPHY/IRIS output to top format.

Currently support for MORPHY's mif filetype is contained in a single script with much redundant code with the modules above.
This needs to be changed.

centerTop.pl - center a topology on the center of mass of its nuclei.

collateMifs.pl - collect the various mif files produced by IRIS into a single file for conversion.

runIris.pl - run the various executables that comprise IRIS on a set of wavefunctions.
