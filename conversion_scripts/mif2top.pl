#!/usr/bin/perl -w
# Dr. Matthew J L Mills - RhoRix
# Convert morphy mif files to the top format

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use Utilities qw(checkArgs readFile getExt stripExt);
use WriteTopology qw(writeTopologyXML);
use ParseMif qw(parseMif);

#### Script Options ###

$remove_redundant =  0; # The .mif filetype includes redundant information on triangulated surfaces. Flag to remove or keep this info.
$print_edges      =  0; # Print edges to the .top file rather than faces (0=no, 1=yes)
$factor           = 10; # Data in .mif files is often scaled - this factor removes the scaling (all coords multiplied by (1/$factor).

# Read the .mif file
$mif_file = checkArgs(\@ARGV,"mif");
if (getExt($mif_file) ne "mif") { die "Error\: $0 script requires a mif file as input\n"; }
$mifContents = readFile($mif_file);

# Get initial info for the .top file
$system_name = stripExt($mif_file,"mif");
my @source_information = ("unknown","unknown","unknown","MORPHY");

if (dirname(__FILE__) =~ m/(.*)\/conversion_scripts/) {
  $dtd_path = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtd_path = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

# Read available data from the mif file
($nucleus_elements, 
$nucleus_indices, 
$nucleus_positions, 
$critical_point_indices, 
$critical_point_ranks, 
$critical_point_signatures, 
$critical_point_coordinates, 
$critical_point_properties,
$molecular_graph_ails,
$molecular_graph_indices,
$molecular_graph_properties,
$as_triangulation_coordinates,
$as_triangulation_properties,
$as_triangulation_edges,
$as_triangulation_faces,) = parseMif($mifContents,$factor,$remove_redundant,$print_edges);

# Due to their not being distinguished from IASs in the mif file, no envelope data can be read.
# Envelopes are instead treated as part of the Atomic Surface and written as IASs.
$envelope_coordinates       = [];
$envelope_properties        = [];
$envelope_indices           = [];
$env_triangulation_edges    = [];
$env_triangulation_faces    = [];
# The gradient path representation of an IAS is also not present in the mif file.
$atomic_surface_coordinates = [];
$atomic_surface_properties  = [];
$atomic_surface_indices     = [];
# Gradient paths connecting RCPs to BCPs are not present in the mif file.
$ring_surface_coordinates   = [];
$ring_surface_indices       = [];
$ring_surface_properties    = [];
# A set of gradient paths representing the complete atomic basin are not present in the mif file.
$atomic_basin_coordinates   = [];
$atomic_basin_properties    = [];
$atomic_basin_indices       = [];

writeTopologyXML($dtd_path,                     #  0
                 $system_name,                  #  1
                 \@source_information,          #  2
                 $nucleus_elements,             #  3 NUCLEI
                 $nucleus_indices,              #  4
                 $nucleus_positions,            #  5
                 $critical_point_indices,       #  6 CRITICAL POINTS
                 $critical_point_ranks,         #  7
                 $critical_point_signatures,    #  8
                 $critical_point_coordinates,   #  9
                 $critical_point_properties,    # 10
                 $molecular_graph_ails,         # 11 MOLECULAR GRAPH
                 $molecular_graph_indices,      # 12
                 $molecular_graph_properties,   # 13
                 $atomic_surface_coordinates,   # 14 ATOMIC SURFACES - TRIANGULATIONS ONLY
                 $atomic_surface_properties,    # 15
                 $atomic_surface_indices,       # 16
                 $as_triangulation_coordinates, # 17
                 $as_triangulation_properties,  # 18
                 $as_triangulation_edges,       # 19
                 $as_triangulation_faces,       # 20
                 $ring_surface_coordinates,     # 21 RING SURFACES - NOT PRESENT
                 $ring_surface_indices,         # 22
                 $ring_surface_properties,      # 23
                 $envelope_coordinates,         # 24 ENVELOPES - NOT PRESENT
                 $envelope_properties,          # 25
                 $envelope_indices,             # 26
                 $env_triangulation_edges,      # 27
                 $env_triangulation_faces,      # 28
                 $atomic_basin_coordinates,     # 29 BASINS - NOT PRESENT
                 $atomic_basin_properties,      # 30
                 $atomic_basin_indices);        # 31

exit 0;
