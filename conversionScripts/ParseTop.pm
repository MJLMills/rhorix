# ParseTop Perl Module
# Dr. Matthew J L Mills - Rhorix v1.0 - June 2017

package ParseTop;
require Exporter;

### Module Settings ###

our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(getNucleiFromTop);
our $VERSION   = 1.0;

### Subroutines ###

sub getNucleiFromTop {

  my @topContents = @{$_[0]};

  my @elements;
  my @coordinates;

  for ($topLine=0; $topLine<@topContents; $topLine++) {

    if ($topContents[$topLine] =~ m/\<Nucleus\>/) {

      for ($cpLine=$topLine; $cpLine<@topContents; $cpLine++) {

        if ($topContents[$cpLine] =~ m/\<x\>(.*)\<\/x\>/) { $x = $1; }
        if ($topContents[$cpLine] =~ m/\<y\>(.*)\<\/y\>/) { $y = $1; }
        if ($topContents[$cpLine] =~ m/\<z\>(.*)\<\/z\>/) { $z = $1; }
        if ($topContents[$cpLine] =~ m/\<element\>(.*)\<\/element\>/) { $element = $1; }

        if ($topContents[$cpLine] =~ m/\<\/Nucleus\>/) {

          my @nuclear_coords = ($x, $y, $z);
          push(@coordinates,\@nuclear_coords);
          push(@elements,$element);

          $topLine = $cpLine+1; # skip CP data
          last; # go to next topoplogy file line

        }

      }

    }

  }

  return \@elements, \@coordinates;

}

