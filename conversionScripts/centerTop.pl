#!/usr/bin/perl -w
# Matthew J L Mills

# Read the .top file (name passed as argument)
$topFile = checkArgs(@ARGV);
@topContents = readFile($topFile);

# Strip all the critical points from the file
my $criticalPoints = getCriticalPoints(\@topContents);

# And then keep only the nuclear attractor CPs
($elements, $cartesianCoords) = getNuclearCoordinates($criticalPoints);

# Convert the element symbols to masses
$masses = getMasses($elements);

# and calculate the center of mass for the system
my $com = computeCOM($masses,$cartesianCoords);
#print "@$com\n";

$topFile =~ m/(.*)\.top/;
open(TOP,">","$1-centered\.top") || die "Cannot create rotated output file\: rotated\.top\n";
# Finally move the whole system to the center of mass
foreach(@topContents) {

  if ($_ =~ m/\<vector\>\s+\<x\>\s*(-?\d+\.\d+)\<\/x\>\s+\<y\>\s*(-?\d+\.\d+)\<\/y\>\s+\<z\>\s*(-?\d+\.\d+)\<\/z\>\s+\<\/vector\>/) {
    $x = $1 - @$com[0];
    $y = $2 - @$com[1];
    $z = $3 - @$com[2];
    printf TOP "\<vector\> \<x\>%10.5f\<\/x\> \<y\>%10.5f\<\/y\> \<z\>%10.5f\<\/z\> \<\/vector\>\n", $x,$y,$z;
  } elsif ($_ =~ m/\<x\>\s*(-?\d+\.\d+)\<\/x\>\s+\<y\>\s*(-?\d+\.\d+)\<\/y\>\s+\<z\>\s*(-?\d+\.\d+)\<\/z\>/) {
    $x = $1 - @$com[0];
    $y = $2 - @$com[1];
    $z = $3 - @$com[2];
    printf TOP "\<x\>%10.5f\<\/x\>\<y\>%10.5f\<\/y\>\<z\>%10.5f\<\/z\>\n", $x,$y,$z;
  } else {
    print TOP "$_\n";
  }

}

#*#*#* SUBROUTINES

sub computeCOM {

  my @masses = @{$_[0]};
  my @cartesianCoordinates = @{$_[1]};

  my $totalMass = 0;
  my @com;
  for($atom=0; $atom<@$masses; $atom++) {

    $totalMass += @$masses[$atom];
    my @coords = @{@{$cartesianCoords}[$atom]};
    for ($i=0; $i<3; $i++) {
      $com[$i] += $coords[$i] * @$masses[$atom];
    }

  }
  if ($totalMass == 0) { die "Total Mass = 0\n"; }
  for ($i=0; $i<3; $i++) {
    $com[$i] /= $totalMass;
  }

  return \@com;

}

sub getMasses {

  my @elements = @{$_[0]};

  my @masses;
  foreach(@elements) {
    push(@masses,getMassFromElement($_));
  }

  return (\@masses);

}

sub getMassFromElement() {

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

sub getNuclearCoordinates {

  my @criticalPoints = @{$_[0]};

  my @elements;
  my @cartesianCoords;
  foreach(@$criticalPoints) {

    my @cp = @{$_};
    foreach(@cp) {
      if ($_ =~ m/<type>(.*)<\/type>/) {
        $type = $1;
        if ($type ne "bcp" && $type ne "rcp" && $type ne "ccp") {
          #type equals the element
          foreach(@cp) {
            if ($_ =~ m/\<x\>\s*(-?\d+\.\d+)\<\/x\>\s+\<y\>\s*(-?\d+\.\d+)\<\/y\>\s+\<z\>\s*(-?\d+\.\d+)\<\/z\>/) {
              my @coords = ($1,$2,$3);
              push(@elements,$type);
              push(@cartesianCoords,\@coords);
            }
          }
        }
      }
    }

  }
  return(\@elements,\@cartesianCoords);

}

sub getCriticalPoints {

  my @topContents = @{$_[0]};

  my @criticalPoints;
  for ($topLine=0; $topLine<@topContents; $topLine++) {
    if ($topContents[$topLine] =~ m/\<CP\>/) {
      for ($cpLine=$topLine; $cpLine<@topContents; $cpLine++) {
        if ($topContents[$cpLine] =~ m/\<\/CP\>/) {
          my @cp = @topContents[$topLine+1 .. $cpLine-1];
          push(@criticalPoints,\@cp);
          $topLine = $cpLine;
          last;
        }
      }
    }
  }

  return \@criticalPoints;

}

sub readFile {

  open(INP,"<","$_[0]") || die "Cannot open input file\: $_[0] for reading\n";
  my @inpContents = <INP>;
  chomp(@inpContents);
  close INP;
  return @inpContents;

}

#Check that 1 arg was passed (the filename)
sub checkArgs {

  my $nArg = @_;
  if ($nArg == 0 || $nArg > 1) {
    die "Incorrect number of arguments\: $nArg\nPlease run script as \"perl newConv.pl filename\"\n";
  } else {
    return "$_[0]";
  }

}
