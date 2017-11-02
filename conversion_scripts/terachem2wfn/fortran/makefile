FC = gfortran
FCFLAGS = -g -ffree-line-length-none -fimplicit-none -fmax-errors=0 -std=f2003 -Wall -Werror -pedantic-errors

PROGRAMS = FormatMO

all: $(PROGRAMS)

FormatMO: FormatMO.o

%: %.o
	$(FC) $(FCFLAGS) -o $@ $^

%.o: %.f90*
	$(FC) $(FCFLAGS) -c $<

clean:
	rm -f *.o *.mod *.MOD
