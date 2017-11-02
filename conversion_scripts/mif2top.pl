#!/usr/bin/perl -w
# Dr. Matthew J L Mills - RhoRix
# Convert morphy mif files to the top format

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use Utilities qw(checkArgs readFile);
use TopUtils qw(getRank getSignature);
use WriteTopology qw(writeTopologyXML);

#### Script Options ###

$removeRedundant = 1;  # The .mif filetype includes redundant information on triangulated surfaces. Flag to remove or keep this info.
$printEdges      = 0;  # Print edges to the .top file rather than faces.
$factor          = 10; # Data in .mif files is often scaled - this factor removes the scaling.

# Read the .mif file

$mifFile = checkArgs(\@ARGV,"mif");
if (getExt($mifFile) ne "mif") { die "Error\: $0 script requires a mif file as input\n"; }
$mifContents = readFile($mifFile);

$systemName = stripExt($mifFile);

if (dirname(__FILE__) =~ m/(.*)\/conversionScripts/) {
  $dtdPath = "$1\/Topology\.dtd";
} else {
  if (-e "../Topology\.dtd") {
    $dtdPath = "\.\.\/Topology\.dtd";
  } else {
    die "Error\: Problem locating Topology\.dtd\n";
  }
}

my @source_information = ("unknown","unknown","unknown","MORPHY"); # perhaps the morphy version can be parsed from the MOUT?

parseMif($mifContents);

writeTopologyXML($dtdPath,                   #  0 done
                 $systemName,                #  1 done
                 $sourceInformation,         #  2 done
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

exit 0;
