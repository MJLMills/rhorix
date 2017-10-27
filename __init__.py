# This file causes Python to treat the directory as containing a package
# The user interface and add-on info are placed here.

# This provides support for reloading of the add-on when making changes
# See https://wiki.blender.org/index.php/Dev:Py/Scripts/Cookbook/Code_snippets/Multi-File_packages
if "bpy" in locals():
    import imp
    imp.reload(ParseTopology)
    imp.reload(TopologyClasses)
    imp.reload(Mapping)
    imp.reload(Materials)
    imp.reload(Resources)
    imp.reload(World)
else:
    from . import TopologyClasses, Mapping, ParseTopology, World, Resources, Materials

import bpy
import time
import fnmatch

# The following dict and 2 functions satisfy the requirements for contributed scripts
# Be sure to also follow the PEP 8 Python conventions
# See https://www.python.org/dev/peps/pep-0008/

# Script Meta-info: this Python dictionary is required by all Addon files
# All possible keys are present in this dict - fill in wiki/tracker URLs later if needed
# See https://wiki.blender.org/index.php/Dev:Py/Scripts/Guidelines/Addons/metainfo

bl_info = {
    "name"        : "Rhorix",
    "description" : "Import and manipulate .top files",
    "author"      : "Matthew J L Mills <mjohnmills@gmail.com>",
    "version"     : (1, 0, 0),
    "blender"     : (2, 79, 0),
    "location"    : "View 3D > Object Mode > Tool Shelf",
    "warning"     : "Be aware of XML vulnerabilities when opening external .top files",
    # link to the wiki page of the script
    "wiki_url"    : "",
    # specify a non-default bug tracker
    "tracker_url" : "",
    "category"    : "Add Mesh",
}

# Function runs only when enabling the addon
def register():
    bpy.utils.register_class(ImportTopology)
    bpy.utils.register_class(RenderStereo)
    bpy.utils.register_class(ResizeAILs)
    bpy.utils.register_class(ResizeNonbondedInteractions)
    bpy.utils.register_class(ResizeRingLines)
    bpy.utils.register_class(ToggleBCPs)
    bpy.utils.register_class(ToggleRCPs)
    bpy.utils.register_class(ToggleCCPs)
    bpy.utils.register_class(RhorixControlPanel)
    bpy.types.INFO_MT_file_import.append(menu_function)

# Function runs only when disabling the addon
# Must undo actions taken by register function in reverse order
def unregister():
    bpy.types.INFO_MT_file_import.remove(menu_function)
    bpy.utils.unregister_class(RhorixControlPanel)
    bpy.utils.unregister_class(ToggleCCPs)
    bpy.utils.unregister_class(ToggleRCPs)
    bpy.utils.unregister_class(ToggleBCPs)
    bpy.utils.unregister_class(ResizeRingLines)
    bpy.utils.unregister_class(ResizeNonbondedInteractions)
    bpy.utils.unregister_class(ResizeAILs)
    bpy.utils.unregister_class(RenderStereo)
    bpy.utils.unregister_class(ImportTopology)

# Classes subclassing the Superclass bpy.types.Operator

class ImportTopology(bpy.types.Operator):

    bl_idname   = "rhorix.import_topology"
    bl_label    = "Import Topology File"
    bl_options  = {'REGISTER'}
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'})
    filepath    = bpy.props.StringProperty(subtype="FILE_PATH")

    def execute(self,context):
        start = time.time()
        top = ParseTopology.parseTopology(self.filepath)
        print('Parse Time ', time.time() - start)
        start = time.time()
        Mapping.drawTopology(top)
        print('Mapping Time', time.time() - start)

        center = top.computeCenter()
        radius = top.computeRadius(top.computeCenter())
        World.setup(center,radius)

        return {'FINISHED'}

    def invoke(self,context,event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

class RenderStereo(bpy.types.Operator):

    bl_idname = "rhorix.render_stereo"
    bl_label = "Render Stereo"

    def invoke(self,context,event):

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

class ResizeAILs(bpy.types.Operator):

    bl_idname = "rhorix.resize_ails"
    bl_label = "Resize AILs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="bond-BevelCircle")
        return {'FINISHED'}

class ResizeNonbondedInteractions(bpy.types.Operator):

    bl_idname = "rhorix.resize_nbs"
    bl_label = "Resize NonbondedInteractions"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="non_bond-BevelCircle")
        return {'FINISHED'}

class ResizeRingLines(bpy.types.Operator):

    bl_idname = "rhorix.resize_ringlines"
    bl_label = "Resize Ring Lines"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="RingSurfaces-BevelCircle")
        return {'FINISHED'}

class ToggleBCPs(bpy.types.Operator):

    bl_idname = "rhorix.toggle_bcps"
    bl_label = "Toggle BCPs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bcps = [obj for obj in bpy.context.scene.objects if fnmatch.fnmatchcase(obj.name, "*bcp*")]
        for bcp in bcps:
            if (bcp.hide == True):
                bcp.hide = False
                bcp.hide_render = False
            else:
                bcp.hide = True
                bcp.hide_render = True

        return {'FINISHED'}

class ToggleRCPs(bpy.types.Operator):

    bl_idname = "rhorix.toggle_rcps"
    bl_label = "Toggle RCPs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        rcps = [obj for obj in bpy.context.scene.objects if fnmatch.fnmatchcase(obj.name, "*rcp*")]
        for rcp in rcps:
            if (rcp.hide == True):
                rcp.hide = False
                rcp.hide_render = False
            else:
                rcp.hide = True
                rcp.hide_render = True

        return {'FINISHED'}

class ToggleCCPs(bpy.types.Operator):

    bl_idname = "rhorix.toggle_ccps"
    bl_label = "Toggle CCPs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        ccps = [obj for obj in bpy.context.scene.objects if fnmatch.fnmatchcase(obj.name, "*ccp*")]
        for ccp in ccps:
            if (ccp.hide == True):
                ccp.hide = False
                ccp.hide_render = False
            else:
                ccp.hide = True
                ccp.hide_render = True

        return {'FINISHED'}

# Classes subclassing the Superclass bpy.types.Panel

class RhorixControlPanel(bpy.types.Panel):
    
    bl_region_type = "TOOLS"      # Appear in the toolshelf (T)
    bl_space_type  = "VIEW_3D"    # when the 3D view
    bl_context     = "objectmode" # is in object mode.
    bl_category    = "Tools"      # Appear in the Create tab of the toolshelf.
    bl_label = "RhoRix Controls"  # The title of the GUI panel

    def draw(self,context):
        uiColumn = self.layout.column(align=True)
        uiColumn.operator("rhorix.import_topology",  text="Import Topology")
        uiColumn.operator("rhorix.render_stereo",    text="Render Stereo")
        uiColumn.operator("rhorix.resize_ails",      text="Resize AILs")
        uiColumn.operator("rhorix.resize_nbs",       text="Resize NBs")
        uiColumn.operator("rhorix.resize_ringlines", text="Resize Ring Lines")
        uiColumn.operator("rhorix.toggle_bcps",      text="Toggle BCPs") 
        uiColumn.operator("rhorix.toggle_rcps",      text="Toggle RCPs")
        uiColumn.operator("rhorix.toggle_ccps",      text="Toggle CCPs")

# Add a menu function for the main operator by defining a new draw function
# and adding it to an existing class (in the register function)
def menu_function(self, context):
    self.layout.operator(ImportTopology.bl_idname, text="Quantum Chemical Topology (.top)")

# Call the register function when run from Blender text editor
if __name__ == "__main__":
    register()
