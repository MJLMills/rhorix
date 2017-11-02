# ParseMif Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseMif;
require Exporter;
use Utilities qw(readFile);

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(parseMif);
our $VERSION   = 1.0;

### Subroutines ###
# To be replaced with their .mif equivalents:

#sub parseMif {} # public subroutine to call private subroutines

# The following are in the mif2top.pl script already
#sub parseCPsFromMif {}

#sub parseAtomicSurfaceFromIasviz {}
#sub parseInteratomicSurfacesFromMif {} # also basins?

#sub parseMolecularGraphFromMif {}
#sub parseGradientPath {}

# Need to check how to do this one
#sub parseNucleiFromMif {}
#sub parseSourceInformationFromViz {} #maybe from a mout?


#sub parseRingSurfacesFromMgpviz { # probs not in mif

#sub determineRings { # leave empty
#sub determineCages { # leave empty

sub parseVertexLine {

  local $line = "$_[0]";
  local $x = undef; local $y = undef; local $z = undef;

  if ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5 * (10 ** $6);
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1; $y = $2; $z = $3 * (10 ** $4);
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1; $y = $2 * (10 ** $3); $z = $4 * (10 ** $5);
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
    $x = $1 * (10 ** $2); $y = $3; $z = $4 * (10 ** $5); 
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
    $x = $1 * (10 ** $2); $y = $3; $z = $4;
  } elsif ($line =~ m/(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
    $x = $1 * (10 ** $2); $y = $3 * (10 ** $4); $z = $5;
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)/) {
    $x = $1; $y = $2 * (10 ** $3); $z = $4;
  } elsif ($line =~ m/(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
    $x = $1; $y = $2; $z = $3;
  }

  if (defined $x) {
    local @vector = ($x, $y, $z);
    return @vector;
  } else {
    return;
  }

}

