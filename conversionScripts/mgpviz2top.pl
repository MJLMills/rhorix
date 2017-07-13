#!/usr/bin/perl -w
# Dr. Matthew J L Mills
# Script to convert plaintext mgpviz output files from AIMAll to XML files conformant to the document model in Topology.dtd.
# Rhorix v1.0

use Utilities     qw(checkArgs getExt readFile stripExt);
use VizUtils      qw(checkMgpvizFile);
use ParseViz      qw(parseMgpviz);
use WriteTopology qw(writeTopologyXML);

# This could be an argument
$dtdPath = "/Users/mjmills/Downloads/blender-2.78c-OSX_10.6-x86_64/blender.app/Contents/Resources/2.78/scripts/addons/rhorix/Topology.dtd";

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

($elements,
$sourceInformation,
$nuclearIndices,
$nuclearCoordinates,
$cpIndices,
$ranks,
$signatures,
$cpCoordinates,
$scalarProperties,
$ails,
$indices,
$props) = parseMgpviz($mgpvizContents,$systemName);

# Write the data to the XML Topology file
writeTopologyXML($dtdPath,
                 $systemName,
                 $sourceInformation,
                 $elements,
                 $nuclearIndices,
                 $nuclearCoordinates,
                 $cpIndices,
                 $ranks,
                 $signatures,
                 $cpCoordinates,
                 $scalarProperties,
                 $ails,
                 $indices,
                 $props);

