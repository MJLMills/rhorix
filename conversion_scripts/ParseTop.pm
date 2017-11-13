#!/usr/bin/perl -w
# ParseTop Perl Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
package ParseTop;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getNucleiFromTop);
our $VERSION   = 1.0;

### Subroutines ###

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

