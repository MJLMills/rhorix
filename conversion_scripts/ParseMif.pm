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

sub reformatSurface {

  my ($xPoints,$yPoints,$zPoints,$edgeA,$edgeB,$faceA,$faceB,$faceC) = @_;
  my @isRedundant; 
  my @xNew; 
  my @yNew; 
  my @zNew;

  $start = time;

  for ($i=0;$i<@$xPoints;$i++) {
    $isRedundant[$i] = 0;
  }

  $n_x = @$xPoints; $n_y = @$yPoints; $n_z = @$zPoints;
  if ($n_x == $n_y && $n_y == $n_z && $n_x != 0) {

    $kept = 0;
    CHECK_POINTS: for ($point=0;$point<@$xPoints;$point++) {

      if ($isRedundant[$point] == 1) {
        next CHECK_POINTS;
      } else {
        push(@xNew,@$xPoints[$point]); push(@yNew,@$yPoints[$point]); push(@zNew,@$zPoints[$point]);
        $kept++; $rep = $kept - 1;

        if ($printEdges == 1) {
          CORRECT_EDGES: for ($j=$point;$j<@$xPoints;$j++) {

#          if ($isRedundant[$j] == 1) { next CORRECT_EDGES; }

            if (@$xPoints[$point] == @$xPoints[$j] && @$yPoints[$point] == @$yPoints[$j] && @$zPoints[$point] == @$zPoints[$j]) {

              if ($point != $j) { $isRedundant[$j] = 1; }

              for ($m=0;$m<@$edgeA;$m++) {
                if (@$edgeA[$m] == $j) {
                  @$edgeA[$m] = $rep;
                } 
                if (@$edgeB[$m] == $j) {
                  @$edgeB[$m] = $rep;
                }
              }
            }
          }
        }

        CORRECT_FACES: for ($j=$point;$j<@$xPoints;$j++) {
        
          if (@$xPoints[$point] == @$xPoints[$j] && @$yPoints[$point] == @$yPoints[$j] && @$zPoints[$point] == @$zPoints[$j]) {

            if ($point != $j) { $isRedundant[$j] = 1; }

            for ($m=0;$m<@$faceA;$m++) {
              if (@$faceA[$m] == $j) { @$faceA[$m] = $rep; }
              if (@$faceB[$m] == $j) { @$faceB[$m] = $rep; }
              if (@$faceC[$m] == $j) { @$faceC[$m] = $rep; }
            }

          }

        }

      }

    }

    $end = time; $elapsed = $end - $start; print "TOOK $elapsed SECONDS TO FIX SURFACE\t";

    if ($n_x > 0) {
      $n_redundant = 0;
      for ($i=0;$i<@$xPoints;$i++) {
        if ($isRedundant[$i] == 1) { $n_redundant++; };
      } 
      $percent = ($n_redundant / $n_x) * 100; $remains = @xNew;
      printf "%d REDUNDANT POINTS \(OF $n_x\) REMOVED \(%5.2f percent\) LEAVING %d\n",$n_redundant,$percent,$remains;
      printSurf(\@xNew, \@yNew, \@zNew, \@$edgeA, \@$edgeB, \@$faceA, \@$faceB, \@$faceC);
    }

  } else {
    die "ERROR: MISMATCHED COORDINATE ARRAYS IN reformatSurface SUBROUTINE\n";
  }

}
