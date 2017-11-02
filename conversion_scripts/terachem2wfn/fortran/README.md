#### Molecular Orbital Formatting

This program (FormatMO) exists to format the unformatted MO coefficients written by TeraChem 1.8 to its output files; c0 (for restricted wavefunctions) or cA and cB (for unrestricted wavefunctions).
Input is provided via the namelist file *params.nml*; it specifies the input file (c0, cA or cB) and the number of primitive Gaussians.
The former is to keep the program simple, the latter is because it was not clear how to infer the number of primitives from the data size.
An example namelist file is provided in params.nml.

Note: The binary MO coefficient file is written by C, meaning ACCESS='stream' from the Fortran2003 spec is needed to read it properly.
To compile and link the program, enter 'make all' at the command line. Requires gfortran and make. Not tested on any other compiler.
