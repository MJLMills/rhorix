#!/usr/bin/perl -w
# Dr. Matthew J L Mills - RhoRix
# Convert morphy mif files to the top format

# The .mif file does not contain the full connectivity of the system! This is a problem.

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use Utilities qw(checkArgs readFile getExt stripExt);
use WriteTopology qw(writeTopologyXML);
use ParseMif qw(parseMif);

#### Script Options ###

$removeRedundant = 0;  # The .mif filetype includes redundant information on triangulated surfaces. Flag to remove or keep this info.
$printEdges      = 0;  # Print edges to the .top file rather than faces.
$factor          = 10; # Data in .mif files is often scaled - this factor removes the scaling.

# Read the .mif file

$mifFile = checkArgs(\@ARGV,"mif");
if (getExt($mifFile) ne "mif") { die "Error\: $0 script requires a mif file as input\n"; }
$mifContents = readFile($mifFile);

# Get initial info for the .top file

$systemName = stripExt($mifFile,"mif");
my @source_information = ("unknown","unknown","unknown","MORPHY"); # perhaps the morphy version can be parsed from the MOUT?

if (dirname(__FILE__) =~ m/(.*)\/conversionScripts/) {
  $dtdPath = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtdPath = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

# add list of returns from parseMif
($elements, 
$nuclearIndices, 
$nuclearCoordinates, 
$cpIndices, 
$ranks, 
$signatures, 
$cpCoordinates, 
$scalarProperties,
$ails,
$indices,
$props) = parseMif($mifContents,$factor,$removeRedundant,$printEdges);

# for now ! These must come from parseMif instead for a complete script
#$ails = [];
#$indices = [];
#$props = [];
$atomic_surface_coords = []; 
$atomic_surface_properties = [];
$atomic_surface_indices = [];
$envelope_coords = [];
$envelope_properties = [];
$envelope_indices = [];

# The following are not present in the mif file so are created as refs to empty arrays.
$ring_surface_coords     = [];
$ring_surface_indices    = [];
$ring_surface_props      = [];
$atomic_basin_coords     = [];
$atomic_basin_properties = [];
$atomic_basin_indices    = [];

writeTopologyXML($dtdPath,                   #  0 done
                 $systemName,                #  1 done
                 \@source_information,       #  2 done
                 $elements,                  #  3 NUCLEI
                 $nuclearIndices,            #  4
                 $nuclearCoordinates,        #  5
                 $cpIndices,                 #  6 CRITICAL POINTS
                 $ranks,                     #  7
                 $signatures,                #  8
                 $cpCoordinates,             #  9
                 $scalarProperties,          # 10
                 $ails,                      # 11 MOLECULAR GRAPH
                 $indices,                   # 12
                 $props,                     # 13
                 $atomic_surface_coords,     # 14 ATOMIC SURFACES
                 $atomic_surface_properties, # 15
                 $atomic_surface_indices,    # 16
                 $ring_surface_coords,       # 17 RING SURFACES - NOT PRESENT
                 $ring_surface_indices,      # 18
                 $ring_surface_props,        # 19
                 $envelope_coords,           # 20 ENVELOPES
                 $envelope_properties,       # 21
                 $envelope_indices,          # 22
                 $atomic_basin_coords,       # 23 BASINS - NOT PRESENT
                 $atomic_basin_properties,   # 24
                 $atomic_basin_indices);     # 25

exit 0;
