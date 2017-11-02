#### TeraChem Compatibility

TeraChem is GPU-enabled software for quantum chemistry (see the [software website](http://www.petachem.com/products.html) for details).
In order to apply QCT analysis software to TeraChem output it is necessary to convert the wavefunction data to a standard format.
To overcome this, the Perl (and associated Fortran) code in this directory reads TeraChem output and writes a corresponding .wfn file.
The background and implementation are described in Section 1 of the [Supporting Information](http://onlinelibrary.wiley.com/store/10.1002/jcc.25054/asset/supinfo/jcc25054-sup-0001-suppinfo.docx?v=1&s=73354cb0aeec467d119dfe4d01cd195c01f3ee51) of the Rhorix paper.
This code applies to TeraChem 1.9, which no longer requires the Fortran component. It is left in case users require TeraChem 1.8 compatibility.

It is unlikely this code will be further updated as the author no longer has access to TeraChem or its associated hardware. 
For this reason it is not incorporated with the remaining Perl component of Rhorix.
