#!/usr/bin/perl -w
# TopUtils Perl Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
package TopUtils;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getRank getSignature getMassesFromElements computeCOM countNACPs findClosestCPToPoint distance);
our $VERSION   = 1.0;

### Subroutines ###

# getRank - Get the integer rank from the string form of a critical point's type
# Arguments: $_[0] - String containing type label
# Return: rank corresponding to the given label
sub getRank {

  local $type = "$_[0]";

  if ($type eq "bcp" or $type eq "rcp" or $type eq "ccp" or $type eq "nacp") {
    return 3;
  } else {
    return 3;
  }
}

# getRank - Get the integer signature from the string form of a critical point's type
# Arguments: $_[0] - String containing type label
# Return: signature corresponding to the given label
sub getSignature {

  local $type = "$_[0]";

  if ($type eq "bcp") {
    return -1;
  } elsif ($type eq "rcp") {
    return 1;
  } elsif ($type eq "ccp") {
    return 3;
  } else {
    return -3;
  }

}

sub getMassFromElement {

  my $element = "$_[0]";

  if ($element eq "H") {
    return 1.0079;
  } elsif ($element eq "C") {
    return 12.0107;
  } elsif ($element eq "N") {
    return 14.0067;
  } elsif ($element eq "O") {
    return 15.9994;
  } elsif ($element eq "P") {
    return 30.9728;
  } elsif ($element eq "S") {
    return 32.065;
  } elsif ($element eq "F") {
    return 18.9984;
  } elsif ($element eq "B") {
    return 10.811;
  } elsif ($element eq "Br") {
    return 79.904;
  } elsif ($element eq "Cl") {
    return 35.453;
  } elsif ($element eq "Se") {
    return 78.96;
  } else {
    die "No mass defined for element $element\n";
  }

}

sub getMassesFromElements {

  my @elements = @{$_[0]};

  my @masses;
  foreach(@elements) {
    $mass = getMassFromElement($_);
    push(@masses,$mass);
  }

  return (\@masses);

}

sub computeCOM {

  my @masses = @{$_[0]};
  my @cartesian_coords = @{$_[1]};

  my $totalMass = 0;
  my @com;
  for($atom=0; $atom<@masses; $atom++) {

    $totalMass += $masses[$atom];
    my @coords = @{$cartesian_coords[$atom]};
    for ($i=0; $i<3; $i++) {
      $com[$i] += $coords[$i] * $masses[$atom];
    }

  }
  if ($totalMass == 0) { die "Error\: Total Mass = 0\n"; }
  for ($i=0; $i<3; $i++) {
    $com[$i] /= $totalMass;
  }

  return \@com;

}

# Routine to count the number of nuclear attractor critical points
sub countNACPs {

  $count = 0;
  for ($cp=0; $cp<@{$_[0]}; $cp++) {
    if (@{$_[0]}[$cp] == 3 && @{$_[1]}[$cp] == -3) {
      $count++;
    }
  }
  return $count;

}

sub findClosestCPToPoint {

  $point      = $_[0];
  @cp_coords  = @{$_[1]};
  @cp_indices = @{$_[2]};

  $closest_index = -1;
  $closest_distance = 100000.0;

  for ($cp=0; $cp<@cp_coords; $cp++) {
    $r = distance($point,$cp_coords[$cp]);
    if ($r < $closest_distance) {
      $closest_distance = $r;
      $closest_index = $cp_indices[$cp];
    }
  }
  return $closest_index;

}


sub distance {

  @vector_a = @{$_[0]};
  @vector_b = @{$_[1]};

  $sum = 0.0;
  for ($i=0; $i<3; $i++) {
    $diff = $vector_a[$i] - $vector_b[$i];
    $sum += $diff * $diff;
  }

  return sqrt($sum);

}

