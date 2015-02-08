&readFile;
open(TOP,">","h2o\.top");
print TOP "\<topology\>\n";

for ($line=0; $line<@vizContents; $line++) {
  if ($vizContents[$line] =~ m/CP\#\s+(\d+)\s+Coords\s+\=\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)\s+(-?\d+\.\d+)E([+-]\d+)/) {
        
    $x = $2 * (10 ** $3);
    $y = $4 * (10 ** $5);
    $z = $6 * (10 ** $7);
        
    if ($vizContents[$line+1] =~ m/Type\s+\=\s+\((-?\d+)\,(-?\d+)\)/) {
      $rank = $1; $signature = $2;
    }

    print "FOUND CP: rank=$rank; signature=$signature\n";
    &printCP;
  }
}

print TOP "\<\/topology\>\n";
close TOP;

sub printCP() {

  print TOP "  \<CP\>\n";
  print TOP "    \<rank\>$rank\<\/rank\>\n";
  print TOP "    \<signature\>$signature\<\/signature\>\n";
  print TOP "    \<x\>$x\<\/x\>\n";
  print TOP "    \<y\>$y\<\/y\>\n";
  print TOP "    \<z\>$z\<\/z\>\n";
  print TOP "  \<\/CP\>\n";

}

sub readFile() {

  open(VIZ,"<","h2o\.sumviz") || die "SPECIFIED FILE NOT PRESENT\n";
  @vizContents = <VIZ>;
  close VIZ;
  chomp(@vizContents);

}
