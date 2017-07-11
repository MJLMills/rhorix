# This file causes Python to treat the directory as containing a package
# The user interface and add-on info are placed here.

# This provides support for reloading of the add-on when making changes
# See https://wiki.blender.org/index.php/Dev:Py/Scripts/Cookbook/Code_snippets/Multi-File_packages
if "bpy" in locals():
    import imp
#    imp.reload(Mapping)
#    imp.reload(Materials)
#    imp.reload(ParseTopology)
#    imp.reload(Resources)
    imp.reload(TopologyClasses)
#    imp.reload(World)
else:
    from . import TopologyClasses

import bpy

# The following satisfy the requirements for contributed scripts
# Be sure to also follow the PEP 8 Python conventions
# See https://www.python.org/dev/peps/pep-0008/

# Script Meta-info: this Python dictionary is required by all Addon files
# All possible keys are present in this dict - fill in wiki/tracker URLs later
# See https://wiki.blender.org/index.php/Dev:Py/Scripts/Guidelines/Addons/metainfo

bl_info = {
    "name"        : "Rhorix",
    "description" : "Import and manipulate .top files",
    "author"      : "Matthew J L Mills <mjohnmills@gmail.com>",
    "version"     : (1, 0, 0),
    "blender"     : (2, 78, 0),
    "location"    : "View 3D > Object Mode > Tool Shelf",
    "warning"     : "Be aware of XML vulnerabilities!",
    # link to the wiki page of the script
    "wiki_url"    : "",
    # specify a non-default bug tracker
    "tracker_url" : "",
    "category"    : "Add Mesh",
}

# Function runs only when enabling the addon
def register():
    print("Hello from register function")
    bpy.utils.register_class(ImportTopology)
    bpy.types.INFO_MT_file_import.append(menu_function)

# Function runs only when disabling the addon
# Must undo actions taken by register function in reverse order
def unregister():
    print("Hello from unregister function")
    bpy.types.INFO_MT_file_import.remove(menu_function)
    bpy.utils.unregister_class(ImportTopology)

# Classes subclassing the Superclass bpy.types.Operator

class ImportTopology(bpy.types.Operator):

    bl_idname   = "rhorix.import_topology"
    bl_label    = "Import Topology File"
    bl_options  = {'REGISTER'}
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'})
    filepath    = bpy.props.StringProperty(subtype="FILE_PATH")

    def execute(self,context):
        print("Hello from ImportTopology execute function")
        return {'FINISHED'}

    def invoke(self,context,event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

# Add a menu function for the main operator by defining a new draw function
# and adding it to an existing class (in the register function)
def menu_function(self, context):
    self.layout.operator(ImportTopology.bl_idname, text="Quantum Chemical Topology (.top)")

# Call the register function when run from Blender text editor
if __name__ == "__main__":
    register()
