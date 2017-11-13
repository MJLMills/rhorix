#!/usr/bin/perl -w
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

# Script to check validity of supplied XML file against its DTD

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use Utilities     qw(checkArgs getExt readFile stripExt);
use XmlRoutines   qw(checkValidity);

my $topFile = &checkArgs(\@ARGV,"top");
print "Validating $topFile\n";
$result = checkValidity($topFile);

if ($result == 1) {
  print "$topFile is valid against DTD\n";
} else {
  print "$topFile is not valid against DTD\n";
}

exit 0;
