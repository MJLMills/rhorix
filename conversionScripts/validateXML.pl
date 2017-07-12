use Utilities     qw(checkArgs getExt readFile stripExt);
use XmlRoutines   qw(checkValidity);

my $topFile = &checkArgs(\@ARGV,"top");
print "Validating $topFile\n";
$result = checkValidity($topFile);

print "RESULT\: $result\n";
