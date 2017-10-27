# TopUtils Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for repeated tasks related to QCT

package TopUtils;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getRank getSignature);
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
