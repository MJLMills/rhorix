# RhoRix (QCT For Blender)

RhoRix is a [Blender](http://www.blender.org) *Add-On* (i.e. a script that extends Blender with extra functionality) that allows the user to import files containing topological objects defined by the theories of [Quantum Chemical Topology](http://www.chemistry.mcmaster.ca/bader/) (QCT). The program converts topological data to 3D objects, and subsequently the full functionality of Blender can be used to render images of the topology. Note that the purpose of this program is to enable import of (and provide a standard appearance for) a topology, and the user is encouraged to consult the full Blender documentation and tutorials in order to obtain creative renders.

The Add-On's Python code is written to adhere to the [Pep-8 Guidelines](http://www.python.org/dev/peps/pep-0008/#introduction).
The initial code was written with reference to Chapter 4 of the WikiBook '[Blender 3D: Noob to Pro](http://en.wikibooks.org/wiki/Blender_3D:_Noob_to_Pro#Table_of_Contents/)' and the appropriate section of the [Blender documentation](https://docs.blender.org/api/blender_python_api_2_78c_release/).
Significant Perl code is provided for conversion of the output of standard QCT programs to the included XML-based filetype. These scripts are provided as a set of traditional modules (sets of subroutines for import).

Full documentation will be provided in 'Manual.pdf', 'Quickstart.pdf' and a peer-reviewed paper.


#### Using the Program

The entire package should be installed by placing the files into your Blender user preferences directory, which will cause Rhorix to appear in the Add-Ons list in the User Preferences window. Doing this directly is OS-dependent and users are advised to consult the Blender documentation. The script will add an operator named 'Import Topology' to the built-in list that can be accessed by pressing the spacebar with the 3D view active. Additionally, the operator is added as a menu item under File -> Import -> Quantum Chemical Topology (.top). Finally, a panel will appear in the left-hand side of the 3D view with an 'Import Topology' button. No keyboard shortcuts are defined.

#### The Name

This program is named for Nicholas Roerich (Nikolai Konstatinovich Rerikh), a Russian artist[1].
Roerich initiated the modern movement for the defense of cultural objects, culminating in the signing of the 'Roerich Pact'.
He shared an interest in the Vedanta school of Indian philosophy with Erwin Schrodinger[2], the first scientist to suggest the charge density as a source of real-world physical concepts[3]. Roerich also provided plotting and visual design for Stravinsky's 'The Rite of Spring'[4], possibly the most influential musical work of the 20th century. The Greek character rho is used in scientific context to represent the charge density, the central scalar field of the Quantum Theory of Atoms in Molecules[5].

#### References

1) Jacqueline Decter, Ph.D - Messenger of Beauty: The Life and Visionary Art of Nicholas Roerich

2) Walter Moore - Schrodinger, Life and Thought & Erwin Schrodinger - My View of the World

3) Erwin Schrodinger - Collected Papers on Wave Mechanics

4) Alex Ross - The Rest is Noise, Listening to the 21st Century

5) Richard F. W. Bader - Atoms in Molecules, A Quantum Theory
