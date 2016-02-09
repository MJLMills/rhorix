#!/usr/bin/perl -w
# Matthew J L Mills
# Convert AIMAll output to .top format.

my $fileName = &checkArgs(@ARGV);
my @fileContents = &readFile($fileName);

$fileName =~ m/(.*)\..*/;
open(TOP,">","$1\.top") || die "Cannot create \.top file\: $1\.top\n";
print TOP "\<topology\>\n";

for ($i=0; $i<@fileContents; $i++) {

  $line = "$fileContents[$i]";

  if    ($line =~ m/CP\#\s+\d+\s+Coords\s+\=/) { &parseCP(@fileContents[$i .. $i+1]) }
  elsif ($line =~ m/CCP/)  {  }

}

print TOP "\<\/topology\>\n";
close TOP;

sub parseCP {

  if ($_[0] =~ m/Coords\s+\=\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)\s+(-?\d+\.\d+E[+-]\d+)/) {
    $x = $1; $y = $2; $z = $3;
  } else { die "Malformed CP line\: $_[0]\n"; }

  if ($_[1] =~ m/Type\s+\=\s+\((\d+)\,([-+]\d+)\)\s+(\w+)\s+(.*)/) {
    $rank = $1; $signature = $2; $type = $3;
    #print "CONNECTIVITY\: $4\n";
  } else { die "Malformed CP line\: $_[1]\n"; }

  &printCP($x,$y,$z,$rank,$signature,$type);
  
}

sub printCP {

  print  TOP "  \<CP\>\n";
  printf TOP "    \<type\>%s\<\/type\>\n", $_[5];
  printf TOP "    \<rank\>%1d\<\/rank\>\n", $_[3];
  printf TOP "    \<signature\>%1d\<\/signature\>\n", $_[4];
  printf TOP "    \<x\>%8.5f\<\/x\> \<y\>%8.5f\<\/y\> \<z\>%8.5f\<\/z\>\n", $_[0], $_[1], $_[2];
  print  TOP "  \<\/CP\>\n";

}

sub readFile {

  open(SVZ,"<","$_[0]") || die "Cannot open file\: $_[0]\n";
  my @sumvizContents = <SVZ>;
  chomp(@sumvizContents);
  close SVZ;
  return @sumvizContents;

}

sub checkArgs {

  my $nArg = @_;
  if ($nArg == 0 || $nArg > 1) {
    die "Incorrect number of arguments\: $nArg\nPlease run script as \"perl newConv.pl filename.sumviz\"\n";
  } else {
    return "$_[0]";
  }

}
