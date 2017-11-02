# TopUtils Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for repeated tasks related to QCT

package TopUtils;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getRank getSignature getMassesFromElements);
our $VERSION   = 1.0;

### Subroutines ###

# getRank - Get the integer rank from the string form of a critical point's type
# Arguments: $_[0] - String containing type label
# Return: rank corresponding to the given label
sub getRank {

  local $type = "$_[0]";

  if ($type eq "bcp" or $type eq "rcp" or $type eq "ccp") {
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

