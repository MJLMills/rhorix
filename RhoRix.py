# RhoRix Main Program
# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

#import xml.etree.ElementTree as ET
import bpy
import mathutils
import math
import resources
import parseTopology as pt
import mapping
from TopologyClasses import *

#Required information for installed Add-On
bl_info = \
{
"name"        : "Rhorix",
"author"      : "Matthew J L Mills <mjohnmills@gmail.com>",
"version"     : (1, 0, 0),
"blender"     : (2, 75, 0),
"location"    : "View 3D > Object Mode > Tool Shelf",
"description" : "Import and manipulate a QCT .top File",
"warning"     : "",
"wiki_url"    : "www.mjohnmills.com",
"tracker_url" : "https://github.com/MJLMills/RhoRix",
"category"    : "Add Mesh",
}

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (subclass of Operator superclass)
# This is the main Rhorix class, invoked either from the File menu or
# through the operator list. It offers the user a file select window,
# attempts to read a topology from the selected file, maps that to a
# set of 3D objects and sets up camera/lights and rendering options.

class Rhorix(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label  = "Import Topology"
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'})
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4B: Opening File " + self.filepath)

        # First create the object representation of the QCT in the .top file
        # by reading the selected topology file.
        topology = pt.readTopology(self.filepath)

        # Create all default materials needed to render this particular topology
        createMaterials(topology.critical_points) # TODO - update to reflect new topology class

        # Create the blender data rep of the QCT and assign materials
        # Anything created herein is persistent.
        # Anything not converted to blender data is lost on save/open of the .blend file
        mapping.drawTopology(topology) # TODO - update to reflect new topology class

        #Setup the environment in which the QCT resides (camera,lights,etc.)
        #setupWorld assumes the system is a sphere containing all of its critical points
        world.setup(topology.findCenter,topology.computeRadius)  # TODO - update to reflect new topology class
        #setupUI()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

#*#*#*#*#*#*#*#*#*#*# HELPER CLASS DEFINITIONS (each a subclass of the Operator superclass)

# This class should select all nuclear critical points of the topology
class SelectNuclei(bpy.types.Operator):

    bl_idname = "qct.select_nuclei"
    bl_label = "Select Nuclei"

    def invoke(self,context,event):
        print("invoke function of SelectNuclei class reporting")
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="*cp*")
        return {'FINISHED'}

# This class should allow the bevel object of the AILs to be re-sized
class ResizeAILs(bpy.types.Operator):

    bl_idname = "qct.resize_ails"
    bl_label = "Resize AILs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="AIL-BevelCircle")
        return {'FINISHED'}

# This class should decide on whether an interaction is a bond or not, and assign an appropriate bevel object
class DifferentiateInteractions(bpy.types.Operator):

    bl_idname = "qct.differentiate_interactions"
    bl_label = "Differentiate Interactions"

    def invoke(self,context,event):
        print ("Differentiating Interactions")
        # check the interatomic distances between AIL-connected nuclei
        # set the appropriate Bevel object for bond or NB interaction

# This class changes options so that the current scene will be rendered stereographically
class RenderStereo(bpy.types.Operator):

    bl_idname = "qct.render_stereo"
    bl_label = "Render Stereo"

    def invoke(self,context,event):
        print("Render Stereo Clicked")
        bpy.context.scene.render.use_full_sample = False
        # These two lines set the values in the Render layers tab
        bpy.context.scene.render.use_multiview = True
        bpy.context.scene.render.views_format = 'STEREO_3D'
        for object in bpy.data.objects: # doesn't work! must set camera only selected and active object
            object.select = False
        bpy.ops.object.select_pattern(pattern="Cam")
        # These 3 lines set the values in the camera's object data tab
        bpy.context.object.data.stereo.convergence_mode = 'OFFAXIS'
        bpy.context.object.data.stereo.convergence_distance = 1.95
        bpy.context.object.data.stereo.interocular_distance = 0.06
        # These 3 lines set the values in the render tab
        bpy.context.scene.render.image_settings.views_format = 'STEREO_3D'
        bpy.context.scene.render.image_settings.stereo_3d_format.display_mode = 'SIDEBYSIDE' #Chip Gardner
        bpy.context.scene.render.image_settings.stereo_3d_format.use_sidebyside_crosseyed = True

        return {'FINISHED'}

#*#*#*#*#*#*#*#*#*#*# CLASS/FUNCTION DEFINITIONS (GUI)

class QCTPanel(bpy.types.Panel):
    
    bl_region_type = "TOOLS"      # Appear in the toolshelf (T)
    bl_space_type  = "VIEW_3D"    # when the 3D view
    bl_context     = "objectmode" # is in object mode.
    bl_category    = "Tools"      # Appear in the Create tab of the toolshelf.
    bl_label = "RhoRix Controls"  # The title of the GUI panel

    def draw(self,context):
        uiColumn = self.layout.column(align=True)
        uiColumn.prop(context.scene, "read_simple_topology")
        uiColumn.operator("qct.import_topology", text="Import Topology")
        uiColumn.operator("qct.select_nuclei",   text="Select Nuclei")
        uiColumn.operator("qct.render_stereo",   text="Render Stereo")
        uiColumn.operator("qct.differentiate_interactions",text="Differentiate Interactions")
        uiColumn.operator("qct.resize_ails",     text="Resize AILs")

def menu_function(self, context):
    self.layout.operator(Rhorix.bl_idname, text="Quantum Chemical Topology (.top)")

#*#*#*#*#*#*#*#*#*#* REQUIRED SCRIPT FUNCTION DEFINITIONS

def register():

    print("QCT4B: Registering Operator Classes")
    print("QCT4B: Use Operator \'Import Topology\' or File -> Import -> \.top to Invoke")
    bpy.utils.register_class(Rhorix)
    bpy.types.INFO_MT_file_import.append(menu_function)
    bpy.utils.register_class(SelectNuclei)
    bpy.utils.register_class(RenderStereo)
    bpy.utils.register_class(ResizeAILs)
    bpy.utils.register_class(DifferentiateInteractions)
    bpy.utils.register_class(QCTPanel)

    bpy.types.Scene.read_simple_topology = bpy.props.BoolProperty \
      (
        name = "Simple Topology",
        description = "Only read CPs and AILs",
        default = False
      )
 
def unregister():

    print("QCT4B: Deregistering Operator Class")
    bpy.utils.unregister_class(Rhorix)
    bpy.utils.INFO_MT_file_import.remove(menu_function)
    bpy.utils.unregister_class(SelectNuclei)
    bpy.utils.unregister_class(RenderStereo)
    bpy.utils.unregister_class(ResizeAILs)
    bpy.utils.unregister_class(DifferentiateInteractions)
    bpy.utils.unregister_class(QCTPanel)
    del bpy.types.Scene.read_simple_topology

if __name__ == "main":
 register()

#For Debugging as text script
#register()


