#!/usr/bin/perl -w
# Matthew J L Mills

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
use TopUtils qw(getMassesFromElements computeCOM);
use Utilities qw(checkArgs readFile stripExt);

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

#*#*#* SUBROUTINES

sub getNucleiFromTop {

  my @topContents = @{$_[0]};

  my @elements;
  my @coordinates;

  for ($topLine=0; $topLine<@topContents; $topLine++) {

    if ($topContents[$topLine] =~ m/\<Nucleus\>/) {

      for ($cpLine=$topLine; $cpLine<@topContents; $cpLine++) {

        if ($topContents[$cpLine] =~ m/\<x\>(.*)\<\/x\>/) { $x = $1; }
        if ($topContents[$cpLine] =~ m/\<y\>(.*)\<\/y\>/) { $y = $1; }
        if ($topContents[$cpLine] =~ m/\<z\>(.*)\<\/z\>/) { $z = $1; }
        if ($topContents[$cpLine] =~ m/\<element\>(.*)\<\/element\>/) { $element = $1; }
 
        if ($topContents[$cpLine] =~ m/\<\/Nucleus\>/) {

          my @nuclear_coords = ($x, $y, $z);
          push(@coordinates,\@nuclear_coords);
          push(@elements,$element);

          $topLine = $cpLine+1; # skip CP data
          last; # go to next topoplogy file line

        }

      }

    }

  }

  return \@elements, \@coordinates;

}
