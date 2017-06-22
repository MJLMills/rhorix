#!/usr/bin/perl -w
# Dr. Matthew J L Mills
# Script to convert plaintext output files from QCT codes to XML format (Topology.dtd)

use Utilities qw(checkArgs getExt readFile stripExt);
use VizUtils qw(checkMgpvizFile);
use ParseViz qw(parseMgpviz);
use WriteTopology qw(writeTopologyXML);

# The single (mandatory) command line argument is the name of the file to convert.
# Must be mgpviz (set -wsp=true); script checks for corresponding atomic iasviz files (-iaswrite=true).

my $mgpvizFile = &checkArgs(\@ARGV,"mgpviz");
if (getExt($mgpvizFile) ne "mgpviz") { die "Error\: Script requires an mgpviz file"; }

$mgpvizContents = readFile($mgpvizFile);
checkMgpvizFile($mgpvizContents);

$systemName = stripExt($mgpvizFile,"mgpviz");

# Attempt to read data from the mgpviz file
($elements,
$nuclearIndices,
$nuclearCoordinates,
$cpIndices,
$ranks,
$signatures,
$cpCoordinates,
$scalarProperties) = parseMgpviz($mgpvizContents,$systemName);

writeTopologyXML($systemName,
                 $elements,
                 $nuclearIndices,
                 $nuclearCoordinates,
                 $cpIndices,
                 $ranks,
                 $signatures,
                 $cpCoordinates,
                 $scalarProperties);

