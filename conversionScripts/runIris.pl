#!/usr/bin/perl -w
# Matthew J L Mills

# Note: most likely doesn't work under Windows since the output is a BASH script.
# Relies on the user having the IRIS executables of the Popelier group.

use Utilities qw(stripExt readFile listFilesOfType);

$psaPath = ""; # This must be the path to morphyPSA on your machine
$ailPath = ""; # This must be the path to morphyAIL on your machine

if ($psaPath eq "" || $ailPath eq "") {
  die "\nError\: Please edit the script to incude paths to the MORPHY executables\n\n";
}

@wfnFiles = listFilesOfType("wfn");
if (@wfnFiles <= 0) { die "Error\: No .wfn files\n"; }

open(MST,">","master-script\.sh");

foreach(@wfnFiles) {

  $system = stripExt($_,"wfn");
  $dir = sprintf("%s\_atomicfiles",$system);
  mkdir $dir || die "Cannot create Iris directory\: $dir\n";
  system("cp $_ $dir");

  printAILinput($system,$dir);

  @wfnContents = readFile($_);
  @atomNames = parseSystem(\@wfnContents);
  foreach (@atomNames) {
    printPSAinput($_,$dir,$system);
  }

  printScript(\@atomNames,$dir,$system);
  print MST "cd $dir\n";
  print MST "\.\/runMORPHY\.sh \&\> runMORPHY.out \&\n";
  print MST "cd \.\.\/\n";

}

close MST;
system("chmod \+x master-script\.sh");

# SUBROUTINES - Being specific to this script's task, these subroutines are kept here.

sub printScript {

  open(SH,">","$_[1]\/runMORPHY\.sh") || die "Cannot open output file\: $_[1]\/runMORPHY\.sh";

  print SH "mv $_[2]-AIL\.11 fort\.11\n";
  print SH "$ailPath\n";
  print SH "mv fort\.11 $_[2]-AIL\.11\n";

  foreach (@{$_[0]}) {
    print SH "mv $_\.11 fort\.11\n";
    print SH "$psaPath\n";
    print SH "mv fort\.11 $_\.11\n";
  }

  close SH;
  system("chmod \+x $_[1]\/runMORPHY\.sh");

}

sub parseSystem {

  foreach (@{$_[0]}) {
    if ($_ =~ m/(\w+)\s+(\d+)\s+\(CENTRE/) {
      push(@atoms,"$1$2");
    }
  }

  return @atoms;

}

sub printPSAinput {

  open(PSA,">","$_[1]\/$_[0]\.11") || die "Cannot open output file\: $_[0]\/$_[0]\.11\n";;

  $_[0] =~ m/\w+(\d+)/;
  $id = $1;

  print PSA "OUTT\n";
  print PSA "      0. 0. 0. 0. 0.\n";
  print PSA "      $_[0]\.mout\n";
  print PSA "WAVE\n";
  print PSA "      1. 0. 0.\n";
  print PSA "      $_[2]\.wfn\n";
  print PSA "INTE\n";
  print PSA "      1. 0. 2. 0. 0.\n";
  print PSA "      $_[0]\.mom\n";
  print PSA "      $_[0]\.mif\n";
  print PSA "      $id.\n";
  print PSA "      1. 1. 1. 1. 1. 1. 1.d-3 1.\n";
  print PSA "      $_[0]\.pod\n";
  print PSA "      $_[0]\.int\n";
  print PSA "TRIA\n";
  print PSA "      $id. 50. 1.d-3 1.3 9.\n";
  print PSA "SHOW\n";
  print PSA "      2. 1. 0.\n";
  print PSA "      $_[0]\.xyz\n";
  print PSA "      50.\n";
  print PSA "STOP\n";

  close PSA;

}

sub printAILinput {

  open(AIL,">","$_[1]\/$_[0]-AIL\.11") || die "Cannot create output file\: $_[1]\/$_[0]-AIL\.11\n";;

  print AIL "OUTT\n";
  print AIL "      0. 0. 0. 0. 0.\n";
  print AIL "      $_[0]\.mout\n";
  print AIL "WAVE\n";
  print AIL "      1. 0. 0.\n";
  print AIL "      $_[0]\.wfn\n";
  print AIL "CRIT\n";
  print AIL "      0. 0. 0. 0. 0. 0. 0.\n";
  print AIL "FITT\n";
  print AIL "      1. 2. 0. 0. 0.\n";
  print AIL "SHOW\n";
  print AIL "      1. 1. 0.\n";
  print AIL "      $_[0]-AIL\.mif\n";
  print AIL "      10.\n";
  print AIL "STOP\n";

  close AIL;

}
