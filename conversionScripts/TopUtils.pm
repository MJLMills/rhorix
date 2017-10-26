# Utilities Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for repeated tasks related to files and command-line arguments.

package TopUtils;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getRank, getSignature);
our $VERSION   = 1.0;

### Subroutines ###

sub getRank {

  local $type = "$_[0]";

  if ($type eq "bcp" or $type eq "rcp" or $type eq "ccp") {
    return 3;
  } else {
    return 3;
  }
}

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
