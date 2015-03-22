# QCT For Blender

This is a [Blender](http://www.blender.org) *Add-On* (i.e. a script that extends Blender with extra functionality) that allows the user to read files containing topological objects defined by the theories of [Quantum Chemical Topology](http://www.chemistry.mcmaster.ca/bader/) and convert them to 3D scenes. Subsequently the full functionality of Blender can be used to render these objects. Note that the purpose of this program is to enable import of (and provide a standard appearance for) a topology, and the user is encouraged to consult the full Blender documentation and tutorials in order to obtain creative renders.
<p>
The code was written with reference to Chapter 4 of the WikiBook '[Blender 3D: Noob to Pro](http://en.wikibooks.org/wiki/Blender_3D:_Noob_to_Pro#Table_of_Contents/)' and the appropriate section of the [Blender documentation](http://wiki.blender.org/index.php/Doc:2.6/Manual/Extensions/). Version 2.69.0 of Blender was used in the development and testing on other versions was not carried out.
<p>
Full documentation will be provided in 'Manual.pdf'.
<p>
######Using the Program
<p>
There are two options for using the script. 
<p>The more permanent solution is installation, i.e. putting the script into your Blender user preferences directory, which will cause it to appear in the Add-Ons list in the User Preferences window. Doing this directly is OS-dependent. This dependence can be avoided by installing from inside Blender. Navigate to User Preferences and choose the 'Add-Ons' tab. Click "Install Add-On" and navigate to the location of the script on your machine. This will copy the script to you personal Add-Ons directory, and it will now appear in the list of available Add-Ons. To activate it you must tick the checkbox for that entry. You can then save the Blender configuration for all future documents, or alternatively tick the Add-On in each document you use for QCT drawing.
<p>
The non-permanent option is to store the script in a text block within your Blender document. This has to be added to each document you make so is less desirable unless you intend to make changes to the script, as it allows for quick editing and reloading of the program. To do this, bring up a Text Editor in a convenient window and click the 'New' button in the window header. Paste the script into the resulting Editor. Press Alt+P to execute the script. After you make changes to the script, pressing Alt+P again will re-execute the script and apply your changes. the location of any Python error messages is OS and execution-environment dependent. Check documentation if you cannot find them.
<p>
Irrespective of the method, the script will add an operator named 'Import Topology' to the built-in list that can be accessed by pressing the spacebar with the 3D view active. Additionally, the operator is added as a menu item under File -> Import -> Quantum Chemical Topology (.top). No keyboard shortcuts are defined.

**Note**: This program does not work yet! See issues for details!
