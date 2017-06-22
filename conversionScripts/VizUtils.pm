package VizUtils;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(checkMgpvizFile);
our $VERSION = 1.0;


### Viz File-Specific Subroutines ###


# checkMgpvizFile - Check validity of an mgpviz file
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkMgpvizFile {

  if (checkPoincareHopf($_[0]) == 0) { print "Warning: Poincare-Hopf Relationship Violated\n"; }
  if (checkCompletion($_[0])   == 0) { print "Warning: .mgpviz File Appears Incomplete\n"; }

}

# checkPoincareHopf - Determine whether CPs reported in mgpviz file satisfies the Poincare-Hopf relationship
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkPoincareHopf {

  for ($line=@{$_[0]}-1; $line>=0; $line--) {
    if (${$_[0]}[$line] =~ m/Poincare-Hopf Relationship is Satisfied/) {
      return 1;
    }
  }
  return 0;

}

# checkCompletion - Check for presence of the final line of an mgpviz file
# Arguments: $_[0] - Reference to array of mgpviz file contents
sub checkCompletion {

  for ($line=@{$_[0]}-1; $line>=0; $line--) {
    if (${$_[0]}[$line] =~ m/Total time for electron density critical point search, analysis and connectivity \=\s+\d+\s+sec \(NProc =\s+\d+\)/) {
      return 1;
    }
  }
  return 0;

}

