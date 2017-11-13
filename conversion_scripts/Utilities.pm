# Utilities Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017
# Subroutines for repeated tasks related to files and command-line arguments.

use File::Basename;
use lib dirname(__FILE__); # find modules in script directory - adds the path to @LIB
package Utilities;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(stripExt getExt readFile checkArgs listFilesOfType);
our $VERSION   = 1.0;

### Subroutines ###

# stripExt - Remove the extension from a filename
# Arguments: $_[0] - name of file
# Return: name of file with extension and . removed (characters before '.')
sub stripExt {
  
  if ($_[0] =~ m/(.*)\.$_[1]/) {
    return $1;
  } else {
    die "Error\: Could not strip extension from $_[0]\n";
  }

}

# getExt - Return the extension from a filename
# Arguments: $_[0] - name of file
# Return: extension of file (characters after '.')
sub getExt {

  if ($_[0] =~ m/.*\.(.*)/) {
    return $1;
  } else {
    die "Error\: Could not determine extension of $_[0]\n";
  }

}

# readFile - Open and read the contents of a file to an array
# Arguments: $_[0] - name of file
# Return: Reference to an array of file contents
sub readFile {

  open(INP,"<","$_[0]") || die "Error: Cannot open $_[0] for reading\n";
  @inpContents = <INP>;
  chomp(@inpContents);
  close INP;

  return \@inpContents;

}

# checkArgs - Check the correct number (1) of arguments is passed to the script and return single argument
# Arguments: $_[0] - Reference to an array of script arguments
#            $_[1] - Extension of the file expected to be passed
# Return: name of file (first element of argument array provided only one element present)
sub checkArgs {

  my $nArg = @{$_[0]};
  my $ext = $_[1];
  if ($nArg == 0 || $nArg > 1) {
    die "Error: Incorrect number of arguments \($nArg\)\nPlease run script as \"perl $0 file\.$ext\"\n";
  } else {
    return "@{$_[0]}[0]";
  }

}

# listFilesOfType - Return a list of all files in the current directory with the extension in the argument
# Arguments: $_[0] - String containing file extension of interest
# Return: List of files in the current directory with the given extension
sub listFilesOfType {

  my $ext = $_[0];
  my @fileList;

  my $dir = ".";
  opendir my($dirHandle), $dir || die "Cannot open directory $dir\: $!";
  for (readdir $dirHandle) {
    if (-d $_) { next; }
    if ($_ =~ m/^[.]/) { next; }
    if ($_ =~ m/(.+)[.]$ext/) {
      push(@fileList,"$_");
    }
  }

  closedir $dirHandle;
  @fileList = sort(@fileList);
  return @fileList;

}

