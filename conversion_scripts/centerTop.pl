#!/usr/bin/perl -w
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use TopUtils qw(getMassesFromElements computeCOM);
use Utilities qw(checkArgs readFile stripExt);
use ParseTop qw(getNucleiFromTop);

# Read the .top file (name passed as argument)
$topFile = checkArgs(\@ARGV,"top");
$topContents = readFile($topFile);

# Strip all the critical points from the file
($elements, $cartesianCoords) = getNucleiFromTop($topContents);

# Convert the element symbols to masses
$masses = getMassesFromElements($elements);

# and calculate the center of mass for the system
my $com = computeCOM($masses,$cartesianCoords);

$fileName = stripExt($topFile,"top");
open(TOP,">","$fileName-centered\.top") || die "Error\:Cannot create rotated output file\n";

# Finally move the whole topology to the center of mass
foreach(@{$topContents}) {

  $edit = 0;
  if ($_ =~ m/\<x\>(.*)\<\/x\>/) {
    printf TOP "\<x\>%10.5f\<\/x\>\n",$1 - @$com[0];
    $edit = 1;
  }

  if ($_ =~ m/\<y\>(.*)\<\/y\>/) {
    printf TOP "\<y\>%10.5f\<\/y\>\n",$1 - @$com[1];
    $edit = 1;
  }

  if ($_ =~ m/\<z\>(.*)\<\/z\>/) {
    printf TOP "\<z\>%10.5f\<\/z\>\n",$1 - @$com[2];
    $edit = 1;
  }

  if ($edit == 0) {
    print TOP "$_\n";
  }

}
