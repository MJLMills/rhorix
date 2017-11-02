#### TeraChem Compatibility

TeraChem is GPU-enabled software for quantum chemistry (see their [website](http://www.petachem.com/products.html) for details).
In order to apply QCT analysis software to TeraChem output it is necessary to convert it to a standard format.
To overcome this, the Perl (and associated Fortran) code in this directory reads TeraChem output and writes a corresponding .wfn file.
The background and implementation are described in Section 1 of the [supplementary material](http://onlinelibrary.wiley.com/store/10.1002/jcc.25054/asset/supinfo/jcc25054-sup-0001-suppinfo.docx?v=1&s=73354cb0aeec467d119dfe4d01cd195c01f3ee51) of the Rhorix paper.
