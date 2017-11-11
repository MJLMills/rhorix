#!/usr/bin/perl -w
# Dr. Matthew J L Mills
# Script to convert plaintext mgpviz output files from AIMAll to XML files conformant to the document model in Topology.dtd.
# Rhorix v1.0
# In scripts, use full name of topological objects unless compound objects are being stored.

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB

use Utilities     qw(checkArgs getExt readFile stripExt);
use VizUtils      qw(checkMgpvizFile);
use ParseViz      qw(parseMgpviz);
use WriteTopology qw(writeTopologyXML);

if (dirname(__FILE__) =~ m/(.*)\/conversion_scripts/) {
  $dtd_path = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtd_path = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

# The single (mandatory) command line argument is the name of the file to convert.
my $mgpviz_file = &checkArgs(\@ARGV,"mgpviz");
# Must be mgpviz format and extension (set -wsp=true); script checks for corresponding atomic iasviz files (-iaswrite=true).
if (getExt($mgpviz_file) ne "mgpviz") { die "Error\: $0 script requires an mgpviz file as input\n"; }

# Read the input file and check for completion
$mgpviz_contents = readFile($mgpviz_file);
checkMgpvizFile($mgpviz_contents);

# Name for the system is taken from the filename
$system_name = stripExt($mgpviz_file,"mgpviz");

# Attempt to read all data from the mgpviz file
# This subroutine also checks for and parses the corresponding iasviz files

($source_information,        # 0
$nucleus_elements,           # 1 
$nucleus_indices,            # 2
$nucleus_positions  ,        # 3
$critical_point_indices,     # 4
$critical_point_ranks,       # 5
$critical_point_signatures,  # 6
$critical_point_coordinates, # 7
$critical_point_properties,  # 8
$molecular_graph_ails,       # 9
$molecular_graph_indices,    # 10
$molecular_graph_props,      # 11
$atomic_surface_coords,      # 12
$atomic_surface_properties,  # 13
$atomic_surface_indices,     # 14
$ring_surface_coords,        # 15
$ring_surface_indices,       # 16
$ring_surface_props,         # 17
$envelope_coords,            # 18
$envelope_properties,        # 19
$envelope_cp_indices,        # 20
$atomic_basin_coords,        # 21
$atomic_basin_properties,    # 22
$atomic_basin_indices) = parseMgpviz($mgpviz_contents,$system_name);

# Triangulation data is not available in viz files - set empty
$as_triangulation_coords = [];
$as_triangulation_props  = [];
$as_triangulation_edges  = [];
$as_triangulation_faces  = [];
$env_triangulation_edges = [];
$env_triangulation_faces = [];

# Write the data to the XML Topology file
writeTopologyXML($dtd_path,                   #  0
                 $system_name,                #  1
                 $source_information,         #  2
                 $nucleus_elements,           #  3 NUCLEI
                 $nucleus_indices,            #  4
                 $nucleus_positions,          #  5
                 $critical_point_indices,     #  6 CRITICAL POINTS
                 $critical_point_ranks,       #  7
                 $critical_point_signatures,  #  8
                 $critical_point_coordinates, #  9
                 $critical_point_properties,  # 10
                 $molecular_graph_ails,       # 11 MOLECULAR GRAPH
                 $molecular_graph_indices,    # 12
                 $molecular_graph_props,      # 13
                 $atomic_surface_coords,      # 14 ATOMIC SURFACES
                 $atomic_surface_properties,  # 15
                 $atomic_surface_indices,     # 16
                 $as_triangulation_coords,    # 17
                 $as_triangulation_props,     # 18
                 $as_triangulation_edges,     # 19
                 $as_triangulation_faces,     # 20
                 $ring_surface_coords,        # 21 RING SURFACES
                 $ring_surface_indices,       # 22
                 $ring_surface_props,         # 23
                 $envelope_coords,            # 24 ENVELOPES
                 $envelope_properties,        # 25
                 $envelope_cp_indices,        # 26
                 $env_triangulation_edges,    # 27
                 $env_triangulation_faces,    # 28
                 $atomic_basin_coords,        # 29
                 $atomic_basin_properties,    # 30
                 $atomic_basin_indices);      # 31

exit 0;
