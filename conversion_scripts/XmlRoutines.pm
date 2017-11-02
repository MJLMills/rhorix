# Utilities Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for tasks related to XML files in general.

use XML::LibXML;

package XmlRoutines;
require Exporter;

### Module Settings ###

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(writePCData openTag closeTag writeXMLHeader checkValidity);
our $VERSION = 1.0;

### Subroutines ###

# writePCData - Write a single parsed character data XML element on a single line
# Arguments: $_[0] - Name of the element
#            $_[1] - Value of the element
sub writePCData {
  print "\<$_[0]\>$_[1]\<\/$_[0]\>\n";
}

# openTag - Write an XML open tag for an element
# Arguments: $_[0] - Name of the element
sub openTag {
  print "\<$_[0]\>\n";
}

# closeTag - Write an XML close tag for an element
# Arguments: $_[0] - Name of the element
sub closeTag {
  print "\<\/$_[0]\>\n";
}

# writeXMLHeader - Write the header of an XML file
# Arguments: $_[0] - XML version number
#            $_[1] - Encoding name
#            $_[2] - Name of root XML tag
#            $_[3] - Path to DTD file
sub writeXMLHeader {

  $version  = $_[0];
  $encoding = $_[1];
  $root     = $_[2];
  $dtdPath  = $_[3];

  print "\<\?xml version\=\"$version\" encoding=\"$encoding\"\?\>\n";
  print "\<\!DOCTYPE $root PUBLIC \"ID\" \"$dtdPath\"\>\n";

}

# CheckValidity - Use LibXML module to check validity of XML file
# Arguments: $_[0] - XML file name
sub checkValidity {

  my $xmlFile = $_[0]; print "Received $xmlFile\n";

  my $parser = XML::LibXML->new(validation => 1,);

  $parser->parse_file($xmlFile);

  my $doc = eval { $parser->parse_file($xmlFile) };
  if (! $doc) {
    return 0;
  } else {
    return 1;
  }

}
