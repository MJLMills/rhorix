# RhoRix (QCT For Blender)

RhoRix is a [Blender](http://www.blender.org) *Add-On* (i.e. a script that extends Blender with extra functionality) that allows the user to read files containing topological objects defined by the theories of [Quantum Chemical Topology](http://www.chemistry.mcmaster.ca/bader/) and convert them to 3D scenes. Subsequently the full functionality of Blender can be used to render these objects. Note that the purpose of this program is to enable import of (and provide a standard appearance for) a topology, and the user is encouraged to consult the full Blender documentation and tutorials in order to obtain creative renders.
<p>
The code is written to adhere to the [PEP-8 guidelines](https://www.python.org/dev/peps/pep-0008/#introduction).
The initial code was written with reference to Chapter 4 of the WikiBook '[Blender 3D: Noob to Pro](http://en.wikibooks.org/wiki/Blender_3D:_Noob_to_Pro#Table_of_Contents/)' and the appropriate section of the [Blender documentation](http://www.blender.org/api/blender_python_api_2_76_2/).
Full documentation will be provided in 'Manual.pdf', 'Quickstart.pdf' and a peer-reviewed paper.

The included conversion programs are implemented in Perl, as a set of traditional modules (sets of subroutines for import).

<p>
#####Using the Program
<p>
There are two options for using the script. 
<p>The more permanent solution is installation, i.e. putting the script into your Blender user preferences directory, which will cause it to appear in the Add-Ons list in the User Preferences window. Doing this directly is OS-dependent. This dependence can be avoided by installing from inside Blender. Navigate to User Preferences and choose the 'Add-Ons' tab. Click "Install Add-On" and navigate to the location of the script on your machine. This will copy the script to your personal Add-Ons directory, and it will now appear in the list of available Add-Ons. To activate it you must tick the checkbox for that entry. You can then save the Blender configuration for all future documents, or alternatively tick the Add-On in each document you use for QCT drawing.
<p>
The non-permanent option is to store the script in a text block within your Blender document. This has to be added to each document you make so is less desirable unless you intend to make changes to the script, as it allows for quick editing and reloading of the program. To do this, bring up a Text Editor in a convenient window and click the 'New' button in the window header. Paste the script into the resulting Editor. Press Alt+P to execute the script. After you make changes to the script, pressing Alt+P again will re-execute the script and apply your changes. The location of any Python error messages is OS and execution-environment dependent. Check documentation if you cannot find them.
<p>
Irrespective of the method, the script will add an operator named 'Import Topology' to the built-in list that can be accessed by pressing the spacebar with the 3D view active. Additionally, the operator is added as a menu item under File -> Import -> Quantum Chemical Topology (.top). No keyboard shortcuts are defined.
<p>
#####The Name
This program is named for Nicholas Roerich (Nikolai Konstatinovich Rerikh), a Russian artist[1].
Roerich initiated the modern movement for the defense of cultural objects, culminating in the signing of the 'Roerich Pact'.
He shared an interest in the Vedanta school of Indian philosophy with Erwin Schrodinger[2], the first scientist to suggest the charge density as a source of real-world physical concepts[3].
Roerich also provided plotting and visual design for Stravinsky's 'The Rite of Spring'[4], possibly the most influential musical work of the 20th century.
<p>
The Greek character rho is used in scientific context to represent the charge density, the central scalar field of Atoms in Molecules[5]; the reason for its inclusion is obvious.
Finally the chi is borrowed from Donald Knuth's TeX typesetting system, tex being an abbreviation for the Greek for 'art' and 'craft', and the root of 'technical'[6].
The name is written 'RhoRix', with the Greek character used when appropriate.
<p>1) Jacqueline Decter, Ph.D - Messenger of Beauty: The Life and Visionary Art of Nicholas Roerich
<p>2) Walter Moore - Schrodinger, Life and Thought & Erwin Schrodinger - My View of the World
<p>3) Erwin Schrodinger - Collected Papers on Wave Mechanics
<p>4) Alex Ross - The Rest is Noise, Listening to the 21st Century
<p>5) Richard F. W. Bader - Atoms in Molecules, A Quantum Theory
<p>6) Donald Knuth - The TeXbook
