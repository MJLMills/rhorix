#!/usr/bin/perl -w
# Matthew J L Mills

use Utilities qw(readFile listFilesOfType);

@mifList = listFilesOfType("mif");
if (@mifList <= 0) {
  die "Error\: No \.mif files\n";
}

my @outputAils;
my @outputSurfaces;
$totalTime = 0;

foreach(@mifList) {
#  print " PARSING $_\n";
  if ($_ =~ m/(.*)\-AIL/) {
    $fileName = "$1";
    @outputAils = readFile($_); 
  } else {
    if ($_ =~ m/(\w+\d+)\.mif/) {
      $atomName = $1;

      @moutContents = readFile("$atomName\.mout");
      $time = parseTime(\@moutContents);
      if ($time != 0) {

        $totalTime += $time;
        my @mifContents = readFile($_);
        foreach (@mifContents) {
          if ($_ =~ m/atom\s+\d+/) {
            push(@outputSurfaces,"atom $atomName");
          } else {
            push(@outputSurfaces,$_);
           }
        }

      } else {
        print "$_ Not Complete\n";
      }
    } else {
      print "Ignoring File\: $_\n";
    }  
  }
}

printOutput(\@outputAils,\@outputSurfaces,$fileName);
print "Total Triangulation Time\: $totalTime s\n";

sub parseTime {

  foreach(@{$_[0]}) {
    if ($_ =~ m/INTEGRATION\s+TIME\s+(-?\d+\.\d+)/) {
      return $1;
    }
  }
  return 0;
}

sub printOutput {

  open(MIF,">","$fileName\.mif") || die "Cannot create output file\: $fileName\.mif\n";

  foreach(@{$_[0]}) {
    print MIF "$_\n";
  }

  foreach(@{$_[1]}) {
    print MIF "$_\n";
  }

  close MIF;

}
