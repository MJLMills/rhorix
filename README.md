# RhoRix (QCT For Blender)

RhoRix is a [Blender](http://www.blender.org) *Add-On* (i.e. a script that extends Blender with extra functionality) that allows the user to import files containing topological objects defined by the theory of [Quantum Chemical Topology](http://www.chemistry.mcmaster.ca/bader/) (QCT). The program converts topological data to 3D objects, and subsequently the full functionality of Blender can be used to render images of the topology. Note that the purpose of this program is to enable import of (and provide a standard appearance for) a topology, and the user is encouraged to consult the full Blender documentation and tutorials in order to obtain creative renders.

The Add-On's Python code is written to adhere to the [Pep-8 Guidelines](http://www.python.org/dev/peps/pep-0008/#introduction).
The initial code was written with reference to Chapter 4 of the WikiBook '[Blender 3D: Noob to Pro](http://en.wikibooks.org/wiki/Blender_3D:_Noob_to_Pro#Table_of_Contents/)' and the appropriate section of the [Blender documentation](https://docs.blender.org/api/blender_python_api_2_78c_release/).
Significant Perl code is provided for conversion of the output of standard QCT programs to the included XML-based filetype. These scripts are provided as a set of traditional modules (sets of subroutines for import).

Full documentation is provided in 'Manual.pdf', 'QuickStart.pdf' and a [peer-reviewed paper](http://dx.doi.org/10.1002/jcc.25054). Building documentation requires LaTeX and the [tufte-latex](https://github.com/Tufte-LaTeX/tufte-latex) package. The .cls files from the package are required to create the pdf documentation.

See the [program website](http://www.mjohnmills.com/rhorix) for further information.

#### Using the Program

The entire package should be installed by placing the files into your Blender user preferences directory, which will cause Rhorix to appear in the Add-Ons list in the User Preferences window. Doing this directly is OS-dependent and users are advised to consult the Blender documentation. The script will add an operator named 'Import Topology' to the built-in list that can be accessed by pressing the spacebar with the 3D view active. Additionally, the operator is added as a menu item under File -> Import -> Quantum Chemical Topology (.top). Finally, a panel will appear in the left-hand side of the 3D view with an 'Import Topology' button. No keyboard shortcuts are defined.

#### Citing the Program

If you use this code to make figures (or parts thereof) for a publication, please cite the paper (details at the [journal page](http://dx.doi.org/10.1002/jcc.25054)) and the software separately as:


Rhorix 1.0.0, M. J. L. Mills, 2017, github.com/MJLMills/RhoRix

#### Contributing, Feature Requests and Bugs

The repo owner intends to continue development of the program and welcomes contributors. Please make contact before making changes and be sure to read the license in LICENSE.txt beforehand. Feature requests and descriptions of issues/bugs can be submitted via the issue tracker.

#### Acknowledgements

This project was initially developed as an employee of Sandia National Laboratories, in the Enzyme Optimization group at the DOE's [Joint BioEnergy Institute](https://www.jbei.org/) under the direction of Dr. Kenneth Sale. Much of the necessary knowledge was developed during the author's graduate studies in the [Quantum Chemical Topology group](http://www.qct.manchester.ac.uk/) of Prof. Paul Popelier at the University of Manchester. The program would not exist without the expert advice and guidance of Mark Forrer.

#### License

This project is licensed under a modified BSD license - see LICENSE.txt for details.

#### Copyright Message

Rhorix Copyright (c) 2017, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy).  All rights reserved.
 
If you have questions about your rights to use or distribute this software, please contact Berkeley Lab's Innovation and Partnerships department at IPO@lbl.gov referring to " Rhorix (2017-158)."
 
NOTICE.  This software was developed under funding from the U.S. Department of Energy.  As such, the U.S. Government has been granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the Software to reproduce, prepare derivative works, and perform publicly and display publicly. The U.S. Government is granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the Software to reproduce, prepare derivative works, distribute copies to the public, perform publicly and display publicly, and to permit others to do so.
