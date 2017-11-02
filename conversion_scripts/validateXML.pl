# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Script to check validity of supplied XML file against its DTD

use Utilities     qw(checkArgs getExt readFile stripExt);
use XmlRoutines   qw(checkValidity);

my $topFile = &checkArgs(\@ARGV,"top");
print "Validating $topFile\n";
$result = checkValidity($topFile);

if ($result == 1) {
  print "$topFile is valid against DTD\n";
} else {
  print "$topFile is not valid against DTD\n";
}
