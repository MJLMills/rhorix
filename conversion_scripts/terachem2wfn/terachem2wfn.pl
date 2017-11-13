#!/usr/bin/perl -w
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

# terachem2wfn.pl - Convert TeraChem 1.9 output files to the PROAIM .wfn format.
# See README.md for further details.

$debug = 0;
# The virial is not provided by TeraChem 1.9 - set to exact value
$virial = 2.0;
# The TeraChem formatted checkpoint filename is hardcoded to post.tcfchk
$tcfchkFile = "post\.tcfchk";

# Produce the expected molden filename ($scratchDirectory/$jobName.molden)
# from the argument, which is the TeraChem input file for the job.

$inpFile = checkArgs(\@ARGV);
print "Input File \(argument\)\: $inpFile\n" if $debug == 1;
$inpContents = readFile($inpFile);
# Get the name of the scratch directory
$scratchDir = parseScratchDir($inpContents);
print "Scratch Directory\:     $scratchDir\n" if $debug == 1;
# Get the name of the job
$jobName = parseJobname($inpContents);
if (! $jobName) {
  # Get the name of the job based on filename and the name of the molden output file
  ($jobName,$moldenFile) = getMoldenFilename($inpFile);
  print "Job Name\:              $jobName \(parsed from $inpFile\)\n" if $debug == 1;
} else {
  $moldenFile = "$jobName\.molden";
  print "Job Name\:              $jobName \(created from name of input file\)\n" if $debug == 1;
}
print "Molden File\:           $moldenFile\n" if $debug == 1;

$wfnFile = "$jobName\.wfn";
print "Wavefunction Output\:   $wfnFile\n" if $debug == 1;

# Parse the missing data (MO energies and occupancies) from the .molden file first in case it is missing
($molecularOrbitalEnergies,$molecularOrbitalOccupancies) = parseMOdata($moldenFile);

# Parse the information provided in the post.tcfchk file
$tcfchkContents = readFile($tcfchkFile);

$energy         = parseEnergy($tcfchkContents);
$coordinates    = parseCartesianCoordinates($tcfchkContents);
$MOCoefficients = parseMolecularOrbitals($tcfchkContents);

($primitiveCenters,
 $primitiveTypes,
 $primitiveExponents,
 $rawMOs) = parseBasisSet($tcfchkContents,$MOCoefficients);

($nMolecularOrbitals,$nNuclei) = parseNumbers($tcfchkContents);
$nPrimitives = @$primitiveCenters;

# Write the data in the .wfn format to $jobName.wfn
writeWFN($nMolecularOrbitals,$nPrimitives,$nNuclei,$energy,$virial,
         $coordinates,$primitiveCenters,$primitiveTypes,$primitiveExponents,$rawMOs,
         $molecularOrbitalEnergies,$molecularOrbitalOccupancies,
         $wfnFile);

exit 0;

### SUBROUTINES ###

# writeWFN writes a PROAIM .wfn file using the data provided as arguments
# As there is no file format spec for this filetype, the read formats from
# Fortran are given prior to each print statement
sub writeWFN {

  #Scalars
  $nMolecularOrbitals = $_[0];
  $nPrimitives        = $_[1];
  $nNuclei            = $_[2];
  $energy             = $_[3];
  $virial             = $_[4];
  #Array References (from .tcfchk)
  $coordinates        = $_[5];
  $primitiveCenters   = $_[6];
  $primitiveTypes     = $_[7];
  $primitiveExponents = $_[8];
  $rawMOs             = $_[9];
  # Array References (from .molden)
  $molecularOrbitalEnergies    = $_[10];
  $molecularOrbitalOccupancies = $_[11];
  # Output Filename
  $wfnName = $_[12];

  open(WFN,">","$wfnName") || die "ERROR\: Cannot create output \.wfn file $wfnName\n";

  print WFN "$wfnName \- parsed from TeraChem output\n";
  # 101 format(a8,11x,i4,2(16x,i4))
  printf WFN "GAUSSIAN           %4d MOL ORBITALS   %4d PRIMITIVES     %4d NUCLEI\n", $nMolecularOrbitals, $nPrimitives, $nNuclei;

  @coordinates = @{$coordinates};
  for ($i=0; $i<@coordinates; $i++) {
    $j = $i+1;
    @atomLine = @{$coordinates[$i]};
    $element = $atomLine[0];
    $x = $atomLine[1]; $y = $atomLine[2]; $z = $atomLine[3];
    # 102 format(a4,i5,15x,3f12.8,10x,f5.1)
    printf WFN "%3s %4d    \(CENTRE%3d\) %12.8f%12.8f%12.8f  CHARGE =%5.1f\n", $element, $j, $j, $x, $y, $z, getNuclearCharge($element);
  }

  # 103 format(20x,20i3)
  $count = 0; $total = 0;
  print WFN "CENTRE ASSIGNMENTS  ";
  foreach (@$primitiveCenters) {
    printf WFN "%3d", $_; $count++; $total++;
    if ($count == 20 && $total != $nNuclei) { print WFN "\nCENTER ASSIGNMENTS  "; $count = 0; }
  }
  if ($count != 0) { print WFN "\n"; }

  # 103 format(20x,20i3)
  $count = 0; $total = 0;
  print WFN "TYPE ASSIGNMENTS    ";
  foreach (@$primitiveTypes) {
    printf WFN "%3d", $_; $count++; $total++;
    if ($count == 20 && $total != $nNuclei) { print WFN "\nTYPE ASSIGNMENTS    "; $count = 0; }
  }
  if ($count != 0) { print WFN "\n"; }

  # 104 format(10x,5e14.7)
  $count = 0; $total = 0;
  print WFN "EXPONENTS ";
  foreach (@$primitiveExponents) {
    printf WFN "%14.7E", $_; $count++; $total++;
    if ($count == 5 && $total != @$primitiveExponents) { print WFN "\nEXPONENTS "; $count = 0; }
  }
  if ($count != 0) { print WFN "\n"; }

  #MO FORMAT
  # 105 format(2x,i5,29x,f13.7,15x,f12.7)  ! GAUSSIAN 94
  # MO    1      MO 0.0        OCC NO =    2.0000000  ORB. ENERGY =   -0.594242
  # 106 format(5e16.8)
  for ($mo=0; $mo<$nMolecularOrbitals; $mo++) {
    printf WFN "MO%5d     MO %3.1f        OCC NO =%13.7f  ORB\. ENERGY =%12.6f\n", $mo+1, 0.0, @$molecularOrbitalOccupancies[$mo], @$molecularOrbitalEnergies[$mo];;
    #now the raw MO coefficients
    $count = 0;
    @row = @{${$rawMOs}[$mo]};
    for ($i=0; $i<$nPrimitives;$i++) {
      printf WFN "%16.8E", $row[$i]; $count++;
      if ($count == 5) { print WFN "\n"; $count = 0; }
    }
      if ($count != 0) { print WFN "\n"; }
  }

  print WFN "END DATA\n";
  # 107 format(17x,f20.12,18x,f13.8)
  printf WFN " TOTAL ENERGY =  %20.12f THE VIRIAL\(-V\/T\)=%13.8f\n", $energy, $virial;

  close WFN;

}

# parseNumbers reads the number of MOs and nuclei from post.tcfchk
sub parseNumbers {

  my @fileContents = @{$_[0]};
  foreach(@fileContents) {
    if ($_ =~ m/(\d+)\s+NumOcc/) {
      $nMolecularOrbitals = $1;
    } elsif ($_ =~ m/(\d+)\s+NumAtoms/) {
      $nNuclei = $1;
    }
  }

  return ($nMolecularOrbitals,$nNuclei);

}

# parseBasisSet reads the basis set, and performs the conversion of the MO coefficients
# ProAIM .wfn defines the integer type codes for primitives up to d-functions as follows:
# 1 2  3  4  5   6   7   8   9   10
# s px py pz dxx dyy dzz dxy dxz dyz
sub parseBasisSet {

  #input arguments
  my @fileContents   = @{$_[0]}; # contents of file containing the specification of the basis set
  my @MOCoefficients = @{$_[1]}; # these are the SCF coefficients (per contraction)

  #initialize output arrays
  my @primitiveCenters;   # P-length 1D array of nuclear centers of each primitive
  my @primitiveTypes;     # P-length 1D array of integer type codes of each primitive
  my @primitiveExponents; # P-length 1D array of gaussian exponent of each primitive
  my @rawMOs;             # P-length 1D array of N_m * d_m * C_n values for each primitive
  # initialize intermediate arrays
  my @contractionCoefficients;           # values of d_m for each primitive
  my @normalizationCoefficients;         # values of N_m for each primitive
  my @normalizedContractionCoefficients; # values of d_m * N_m for each primitive
  my @contractionIDs;                    # integer index of the contraction to which each primitive belongs
  my @contractionTypes;                  # s,p or d type of each of the N contractions

  print "\nParsing Basis Set\:\n\n" if $debug == 1;
  print "Type    alpha     center d               N              contraction primitive\n" if $debug == 1;

  for ($line=0; $line<@fileContents; $line++) {
    
    if ($fileContents[$line] =~ m/(\d+)\s+NumPrimitives/) {
      $nPrimitives = $1;
    } elsif ($fileContents[$line] =~ m/(\d+)\s+NumOcc/) {
      $nOccupied = $1;
    } elsif ($fileContents[$line] =~ m/ATOMIC\s+BASIS\s+SET/) {
      $center = 0; # Keep track of which nucleus the functions are centered on
      $p      = 0; # Keep track of the ID of the primitives
      $offset = 0;
      # The contraction IDs of s-type primitives can be used directly.
      # For p and d primitives, they need to increase sequentially for each of 3 or 6 primitives.
      # This is done by adding an offset value of either 0, 2 or 5 for each primitive encountered.
      for ($m=$line+1; $m<@fileContents; $m++) {

        if ($fileContents[$m] =~ m/\s+(\d+)\s+(\w+)\s+\d+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {

          $canWrite = 1;                # Specifies that a contraction has ended
          $contractionID = $1;          # The contraction TeraChem says this primitive belongs to
          $primitiveType = $2;          # The type of the newly located primitive,
          $primitiveExponent = $3;      # its exponent alpha,
          $contractionCoefficient = $4; # and its contraction coefficient d_m

          # get normalization constants, integer type-codes and indices for each primitive 
          # created from this line of the basis set
          # i.e. do any necessary expansion of p,d primitives
          ($coeffs,$types,$IDs) = produceNormalizationCoefficients($primitiveType,$primitiveExponent,$contractionID+$offset);

          # Copy all information to the per-primitive arrays
          # Could just as well run over coeffs or IDs
          for($type=0; $type<@$types; $type++) {
            printf "%1s %02d %12.7f %05d %15.12f %15.12f %04d        %06d\n", $primitiveType, @$types[$type], 
                                                                              $primitiveExponent, $center, 
                                                                              $contractionCoefficient, @$coeffs[$type], 
                                                                             @$IDs[$type]-1, $p if $debug == 1;

            push(@primitiveTypes,@$types[$type]);                   # integer type code (per primitive)
            push(@primitiveExponents,$primitiveExponent);           # alpha (same for all primitives)
            push(@primitiveCenters,$center);                        # A (same for all primitives)
            push(@contractionCoefficients,$contractionCoefficient); # d_m (same for all primitives)
            push(@contractionIDs,@$IDs[$type]-1);                   # n for primitive m
            push(@normalizationCoefficients,@$coeffs[$type]);       # N_m (per primitive)
            push(@normalizedContractionCoefficients, @$coeffs[$type] * $contractionCoefficient);
            $p++; # count the total primitives
          }


        } elsif ($fileContents[$m] =~ m/(\w+)/ && $fileContents[$m] !~ m/SCF Energy/) {
          # atom elements printed in the basis set mark the beginning of a new center
          $center++; 
          $m++; # skips a blank line following the atom specification
          print "$1 $center\n\n" if $debug == 1;
        } elsif ($fileContents[$m] =~ m/SCF Energy/) {
          #at this point we are done parsing the basis set and exit the loop
          last;
        } else {
          # A blank line delineates the contractions, i.e. done parsing all primitives in a given contraction
          $offset += @$IDs - 1;
          print "\n" if $canWrite == 1 && $debug == 1;
          # this contraction has ended
          if ($canWrite == 1) {
            if (lc($primitiveType) eq "s") {
              push(@contractionTypes,$primitiveType);
            } elsif (lc($primitiveType) eq "p") {
              for ($i=0; $i<3; $i++) { push(@contractionTypes,$primitiveType); }
            } elsif (lc($primitiveType) eq "d") {
              for ($i=0; $i<6; $i++) { push(@contractionTypes,$primitiveType); }
            }
            $canWrite = 0;
          }
        }
  
      }      
    }
  }
  
  $nPrimitives = @primitiveTypes;
  # Now need to compute the final MO coefficients, i.e. for each primitive need to write
  # c_n * d_m * N_m where d_m and N_m are already in per-primitive arrays
  # and the problem is mapping them to the correct contraction coefficients
  $rawMOs = normalizeMolecularOrbitals($nPrimitives,$nOccupied,\@normalizedContractionCoefficients,\@MOCoefficients,\@contractionIDs,\@contractionTypes);

  return (\@primitiveCenters,\@primitiveTypes,\@primitiveExponents,$rawMOs);

}

# This is the annoying/confusing part.
# The MO coefficients are listed in the order s-type; A,B,C,...; p-type; A,B,C,...; d-type; A,B,C,...
# and have to be rearranged.
sub normalizeMolecularOrbitals {

  print "\nForming Raw Normalized Molecular Orbital Coefficients\n\n" if $debug == 1;

  $nPrimitives = $_[0];
  $nOccupied = $_[1];
  $normalizedContractionCoefficients = $_[2];
  $MOCoefficients = $_[3]; @MOCoeffs = @{$MOCoefficients};
  $contractionIDs = $_[4];
  $contractionTypes = $_[5];

  # Deal with the fact that the contractionIDs in the basis set and MO coefficient listings are not the same
  my @map = @{getMap($contractionTypes,$contractionIDs)};

  # Finally we need to return the raw MO data, i.e. c_n * d_m * N_m for each MO
  for ($mo=0; $mo<$nOccupied; $mo++) {
    # There is a single raw MO coefficient for every primitive
    print "\nMolecular Orbital $mo\np contraction dNorm MOCoefficient\n" if $debug == 1;
    my @rawCoeffs;

    for ($p=0; $p<$nPrimitives; $p++) {
      # goal here is to get the correct MO coefficient for the contraction that this primitive is a member of.
      # the contractionIDs array contains the contraction IDs for each primitive read from the basis set section
      $contractionID = @$contractionIDs[$p];
      # correct the preceding to get the REAL index after the reordering of the post.tcfchk MOs
      $contractionID = $map[$contractionID];
      # Now can get the row of the MO coefficient matrix corresponding to the contraction ID of this primitive as an array by dereferencing
      @contractionContributions = @{$MOCoeffs[$contractionID]};
      # and finally can get the contribution of the contraction to the specific MO
      $MOCoefficient = $contractionContributions[$mo];
      # now dereference the correct value of the normalized contraction coefficient for this primitive
      $normD = @{$normalizedContractionCoefficients}[$p];
      print "$p $contractionID $normD $MOCoefficient\n" if $debug == 1;

      push(@rawCoeffs,$normD * $MOCoefficient);

    }
    push(@rawMOs,\@rawCoeffs);
  }

  return \@rawMOs;

}

# parseMolecularOrbitals reads the (per-contraction) MO coefficients from a post.tcfchk file.
sub parseMolecularOrbitals {

  my @MOCoefficients;

  print "\nMolecular Orbital Coefficients\n\n" if $debug == 1;

  my @fileContents = @{$_[0]};
  for ($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/(\d+)\s+NumOrbitals/) {
      $nOrbitals = $1;
    } elsif ($fileContents[$line] =~ m/Occupied MO Coefficients after SCF/) {
      for ($mo=$line+1; $mo<$line+1+$nOrbitals; $mo++) {
        my @orbital = split /\s+/, $fileContents[$mo];
        print "@orbital\n" if $debug == 1;
        push(@MOCoefficients,\@orbital);
      }

    }

  }

  return \@MOCoefficients;

}

# readFile returns a reference to an array of the contents of scalar argument $_[0] with line-endings removed. 
sub readFile {

  my $fileName = "$_[0]";
  my @fileContents;

  open(INP,"<","$fileName") || die "ERROR: FILE $fileName DOES NOT EXIST\n";
  @fileContents = <INP>;
  close INP;
  chomp(@fileContents);
  
  return \@fileContents;
  
}

# parseEnergy retrieves the SCF Energy from a post.tcfchk file
sub parseEnergy {

  my @fileContents = @{$_[0]};
  for($line=0; $line<@fileContents; $line++) {
    if ($fileContents[$line] =~ m/SCF Energy/) {
      if ($fileContents[$line+1] =~ m/(-?\d+\.\d+e[+-]\d+)/) {
        return $1;
      } else {
        die "ERROR IN parseEnergy\: Malformed energy line\: $tcfchkContents[$line+1]\n";
      }
    }
  }

}

# parseCartesianCoordinates retrieves the Cartesian coordinates and elements from a post.tcfchk file
sub parseCartesianCoordinates {

  my @cartesianCoordinates;

  my @fileContents = @{$_[0]};
  for ($line=0; $line<@fileContents; $line++) {

    if ($fileContents[$line] =~ m/(\d+)\s+NumAtoms/) {
      $nAtoms = $1;
    } elsif ($fileContents[$line] =~ m/ATOM\s+ATOMIC\s+COORDINATES\s+\(BOHR\)/) {

      for ($atom=$line+1; $atom<$line+1+$nAtoms; $atom++) {
        if ($fileContents[$atom] =~ m/(\w+)\s+\d+\.\d+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)/) {
          my @atomCoords = ($1,$2,$3,$4);
          push(@cartesianCoordinates,\@atomCoords);
        }
      }

    }

  }

  return \@cartesianCoordinates;

}

# p and d primitives are written in the basis set files as a single entry with contraction coefficient and exponent
# these primitives must be duplicated 3 or 6 times respectively in the .wfn file
# The normalization coefficients are also computed in this subroutine. 
sub produceNormalizationCoefficients {

  $type = lc("$_[0]"); # s, p or d
  $exponent = $_[1];   # exponent of the primitive (needed to normalize)
  $startID = $_[2];    # whole-wfn index of 1st primitive produced by the routine

  my @coeffs; # N_m for each primitive produced from this basis function
  my @types;  # Integer type codes for each primitive produced from this basis function
  my @IDs;    # Consecutive indices for each primitive of the whole wavefunction

  # For s-type functions just return type of 1 and single normalization coefficient
  if ($type eq "s") { 

    push(@coeffs,computeNormalizationCoefficient(0,0,0,$exponent));
    push(@types,1);
    push(@IDs,$startID);

  # p-type functions are in the order x,y,z=2,3,4 and share 1 normalization coefficient
  } elsif ($type eq "p") {

    # produce p-functions in order x, y, z = 2, 3, 4
    push(@coeffs,computeNormalizationCoefficient(1,0,0,$exponent));
    push(@types,2);
    push(@coeffs,computeNormalizationCoefficient(0,1,0,$exponent));
    push(@types,3);
    push(@coeffs,computeNormalizationCoefficient(0,0,1,$exponent));
    push(@types,4);
    for ($i=0; $i<3; $i++) {
      push(@IDs,$startID+$i);
    }

  } elsif ($type eq "d") {

    # TeraChem produces Cartesian d-functions in order xy,xz,yz,xx,yy,zz
    # So the appropriate type markers are written here.
    push(@coeffs,computeNormalizationCoefficient(1,1,0,$exponent));
    push(@types,8); # xy
    push(@coeffs,computeNormalizationCoefficient(1,0,1,$exponent));
    push(@types,9); # xz
    push(@coeffs,computeNormalizationCoefficient(0,1,1,$exponent));
    push(@types,10); # yz
    push(@coeffs,computeNormalizationCoefficient(2,0,0,$exponent));
    push(@types,5); # xx
    push(@coeffs,computeNormalizationCoefficient(0,2,0,$exponent));
    push(@types,6); # yy
    push(@coeffs,computeNormalizationCoefficient(0,0,2,$exponent));
    push(@types,7); # zz
    for ($i=0; $i<6; $i++) {
      push(@IDs,$startID+$i);
    }

  }

  return (\@coeffs,\@types,\@IDs);

}

# shortcuts the full expression for s and p orbitals
# use full expression for d and higher orbitals
# See for example Levine, Szabo&Ostlund
# For the formula see Levine, Quantum Chemistry; Szabo&Ostlund, Modern Quantum Chemistry for example. 

sub computeNormalizationCoefficient {

  $pi = 3.141592653589793;

  $i = $_[0];
  $j = $_[1];
  $k = $_[2];
  $exponent = $_[3];

  $sum = $i + $j + $k;

  $prefactor = ((2.0*$exponent)/$pi) ** (3.0/4.0);
  if ($sum == 0) { #s-orbital
    return $prefactor;
  } elsif ($sum == 1) { #p-orbital
    return $prefactor * 2.0 * sqrt($exponent);
  } elsif ($sum >= 2) { #d-orbital or higher angular momentum
    $numerator = ((8.0*$exponent)**$sum) * factorial($i) * factorial($j) * factorial($k);
    $denominator = factorial(2*$i) * factorial(2*$j) * factorial(2*$k);
    return $prefactor * sqrt($numerator / $denominator);
  }

}

#Quick+dirty no-module factorial subroutine since N will never be larger than 4.
#See http://perlmaven.com/factorial-in-perl
sub factorial {
  
  my $f = 1;
  my $i = 1;
  my $N = $_[0];

  $f *= ++$i while $i < $N;

  return $f;

}

# Determine the correct MO indices for each primitives
sub getMap {

  @contractionTypes = @{$_[0]};
  @contractionIDs   = @{$_[1]};

  print "\nCorrecting Molecular Orbital Indices\n\n" if $debug == 1;

  my @s; 
  my @p;
  my @d;

  # First collect all s-orbitals
  for ($index=0; $index<@contractionTypes; $index++) {
    $type = lc($contractionTypes[$index]);
    if ($type eq "s") {
      push(@s,$index);
    } 
  }

  # Then collect all p-orbitals
  for ($index=0; $index<@contractionTypes; $index++) {
    $type = lc($contractionTypes[$index]);
    if ($type eq "p") {
        push(@p,$index);
    }
  }

  # Then collect all d-orbitals
  for ($index=0; $index<@contractionTypes; $index++) {
    $type = lc($contractionTypes[$index]);
    if ($type eq "d") {
        push(@d,$index);
    }
  }

  # now concatenate them in the order s,p,d
  # This is now a list mapping MO indices to primitive indices
  @map = (@s, @p, @d);
  # However we want to map primitive indices to MO indices so need to reverse the mapping
  for ($m=0; $m<@map; $m++) {
    $revMap[$map[$m]] = $m;
  }
  return \@revMap;

}

# parseMOdata retrieves the MO energies and occupancies from the .molden file
# Necessary because this information is not written to post.tcfchk
sub parseMOdata {

  my @molOrbitalEnergies;
  my @molOrbitalOccupancies;

  @molContents = @{&readFile($_[0])};
  for ($i=0; $i<@molContents; $i++) {
    if ($molContents[$i] =~ m/\[MO\]/) {
      for ($line=$i+1; $line<@molContents; $line++) {

        if ($molContents[$line] =~ m/Ene=\s+(-?\d+\.\d+)/) {
          push(@molOrbitalEnergies,$1);
        } elsif ($molContents[$line] =~ m/Occup=\s+(-?\d+\.\d+)/) {
          push(@molOrbitalOccupancies,$1);
        }

      }
    }
  }
  return (\@molOrbitalEnergies,\@molOrbitalOccupancies);

}

# Subroutine checkArgs
# Check that 1 command line argument was passed and return it as a scalar.
#
# Input - Reference to array of command line arguments passed to program, @ARGV
# Output - Array containing name of input file of Terachem job
sub checkArgs {

  #dereference the array reference to @args
  my @args = @{$_[0]};

  my $nArg = @args;
  if ($nArg != 1) {
    die "Incorrect number of arguments\: $nArg\nPlease run script as \"perl terachem2wfn.pl filename.extension\"\n";
  } else {
    return $args[0];
  }

}

# check if the user added a non-default scratch folder name in the TeraChem input file
sub parseScratchDir {

  foreach(@{$_[0]}) {
    if ($_ =~ m/scrdir\s+(.*)/) {
      return $1;
    }
  }
  return "scr"; #default
}

sub parseJobname {

  foreach(@{$_[0]}) {
    if ($_ =~ m/jobname\s+(.*)/) {
      return $1;
    }
  }
  return; #default

}

#generate the name of the .molden file and the job name from the input filename
sub getMoldenFilename {

  if ($_[0] =~ m/(.*)\..*/) { 
    # TeraChem places the .molden file in the scratch directory of the job as jobName.molden
    $jobName = $1;
    $moldenFile = "$scratchDir\/$jobName\.molden";
    return ($jobName,$moldenFile);
  } else {
    # Have to fail without knowledge of where to get the MO energies/occupancies
    die "ERROR: Could not parse filename $_[0] as argument\n";
  }

}

# Wavefunctions require the nuclear charge explicitly, but the TeraChem output has it implicit in the element name of the atoms.
# This routine provides conversion from element to Z, up to element 20.
sub getNuclearCharge {

  $e = uc("$_[0]");

  if ($e eq "H") {
    return 1;
  } elsif ($e eq "HE") {
    return 2;
  } elsif ($e eq "LI") {
    return 3;
  } elsif ($e eq "BE") {
    return 4;
  } elsif ($e eq "B") {
    return 5;
  } elsif ($e eq "C") {
    return 6;
  } elsif ($e eq "N") {
    return 7;
  } elsif ($e eq "O") {
    return 8;
  } elsif ($e eq "F") {
    return 9;
  } elsif ($e eq "NE") {
    return 10;
  } elsif ($e eq "NA") {
    return 11;
  } elsif ($e eq "MG") {
    return 12;
  } elsif ($e eq "AL") {
    return 13;
  } elsif ($e eq "SI") {
    return 14;
  } elsif ($e eq "P") {
    return 15;
  } elsif ($e eq "S") {
    return 16;
  } elsif ($e eq "CL") {
    return 17;
  } elsif ($e eq "AR") {
    return 18;
  } elsif ($e eq "K") {
    return 19;
  } elsif ($e eq "CA") {
    return 20;
  } else {
    die "No charge in library for atom $_[0]\.\nConsider adding this atom to the getNuclearCharge subroutine\.\n";
  }
}
