#!/usr/bin/perl -w
# Dr. Matthew J L Mills
# Script to convert plaintext mgpviz output files from AIMAll to XML files conformant to the document model in Topology.dtd.
# Rhorix v1.0

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB

use Utilities     qw(checkArgs getExt readFile stripExt);
use VizUtils      qw(checkMgpvizFile);
use ParseViz      qw(parseMgpviz);
use WriteTopology qw(writeTopologyXML);

if (dirname(__FILE__) =~ m/(.*)\/conversion_scripts/) {
  $dtdPath = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtdPath = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

# The single (mandatory) command line argument is the name of the file to convert.
my $mgpvizFile = &checkArgs(\@ARGV,"mgpviz");
# Must be mgpviz format and extension (set -wsp=true); script checks for corresponding atomic iasviz files (-iaswrite=true).
if (getExt($mgpvizFile) ne "mgpviz") { die "Error\: $0 script requires an mgpviz file as input\n"; }

# Read the input file and check for completion
$mgpvizContents = readFile($mgpvizFile);
checkMgpvizFile($mgpvizContents);

# Name for the system is taken from the filename
$systemName = stripExt($mgpvizFile,"mgpviz");

# Attempt to read all data from the mgpviz file
# This subroutine also checks for and parses the corresponding iasviz files

($sourceInformation,        # 0
$elements,                  # 1 
$nuclearIndices,            # 2
$nuclearCoordinates,        # 3
$cpIndices,                 # 4
$ranks,                     # 5
$signatures,                # 6
$cpCoordinates,             # 7
$scalarProperties,          # 8
$ails,                      # 9
$indices,                   # 10
$props,                     # 11
$atomic_surface_coords,     # 12
$atomic_surface_properties, # 13
$atomic_surface_indices,    # 14
$ring_surface_coords,       # 15
$ring_surface_indices,      # 16
$ring_surface_props,        # 17
$envelope_coords,           # 18
$envelope_properties,       # 20
$envelope_indices,          # 21
$atomic_basin_coords,       # 22
$atomic_basin_properties,   # 23
$atomic_basin_indices) = parseMgpviz($mgpvizContents,$systemName);

# Write the data to the XML Topology file
writeTopologyXML($dtdPath,                   #  0
                 $systemName,                #  1
                 $sourceInformation,         #  2
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
                 $ring_surface_coords,       # 17 RING SURFACES
                 $ring_surface_indices,      # 18
                 $ring_surface_props,        # 19
                 $envelope_coords,           # 20 ENVELOPES
                 $envelope_properties,       # 21
                 $envelope_indices,          # 22
                 $atomic_basin_coords,       # 23
                 $atomic_basin_properties,   # 24
                 $atomic_basin_indices);     # 25

