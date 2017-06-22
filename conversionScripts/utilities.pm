package Utilities;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(stripExt getExt readFile checkArgs);
our $VERSION = 1.0;

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

