# Matthew J L Mills - RhoRix Main Program
# www.mjohnmills.com/rhorix

import xml.etree.ElementTree as ET
import bpy
import mathutils
import math
import parseTopology as pt
from TopologyClasses import *

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (OPERATOR)

class Rhorix(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label  = "Import Topology"
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'})
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4B: Opening File " + self.filepath)
        # First create the object representation of the QCT in the .top file
        # by reading them from the selected topology file.
        topology = pt.readTopology(self.filepath) # TODO - replace with function in ParseTopology.py
        # Create all default materials needed to render this particular topology
        createMaterials(topology.sphereList) # TODO - update to reflect new topology class
        # Create the blender data rep of the QCT and assign materials
        # Anything created herein is persistent.
        # Anything not converted to blender data is lost on save/open of the .blend file
        createBlenderObjects(topology) # TODO - update to reflect new topology class
        #Setup the environment in which the QCT resides (camera,lights,etc.)
        setupWorld(topology.sphereList)  # TODO - update to reflect new topology class
        #setupUI()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (GUI OPERATOR)
# This class should select all nuclear critical points of the topology
class SelectNuclei(bpy.types.Operator):

    bl_idname = "qct.select_nuclei"
    bl_label = "Select Nuclei"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="*cp*")
        return {'FINISHED'}

class ResizeAILs(bpy.types.Operator):

    bl_idname = "qct.resize_ails"
    bl_label = "Resize AILs"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.select = False
        bpy.ops.object.select_pattern(pattern="AIL-BevelCircle")
        return {'FINISHED'}

class DifferentiateInteractions(bpy.types.Operator):

    bl_idname = "qct.differentiate_interactions"
    bl_label = "Differentiate Interactions"

    def invoke(self,context,event):
        print ("Differentiating Interactions")
        # check the interatomic distances between AIL-connected nuclei
        # set the appropriate Bevel object for bond or NB interaction

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (GUI OPERATOR)
# This class renders the current scene from the camera in stereo
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

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (GUI)

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

#*#*#*#*#*#*#*#*#*#* SCRIPT FUNCTION DEFINITIONS

def menu_function(self, context):
    self.layout.operator(Rhorix.bl_idname, text="Quantum Chemical Topology (.top)")

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

# This function carries out the mapping from topological objects to 3D objects.
def createBlenderObjects(topology):

    sphereList  = topology.sphereList
    lineList    = topology.lineList
    surfaceList = topology.surfaceList
    gvfList     = topology.gvfList

    if (len(sphereList) > 0):
      bpy.ops.group.create(name="Critical_Points")    

    elementRadii = defineRadii()
    #create a UV sphere for each CP
    for cp in sphereList:

        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cp.position,size=0.1*elementRadii[cp.type],segments=8,ring_count=4)
        bpy.context.object.name = cp.type

        #Create and apply the subsurface modifiers for smooth rendering
        bpy.context.object.modifiers.new("subd", type='SUBSURF')
        bpy.context.object.modifiers['subd'].levels=1
        bpy.context.object.modifiers['subd'].render_levels=4
        bpy.context.scene.objects.active = bpy.context.object
        bpy.ops.object.modifier_apply(apply_as='DATA', modifier='subd')

        bpy.ops.object.group_link(group="Critical_Points")

        #The necessary materials are created in the createMaterials function
        materialName = cp.type.lower() + '-CriticalPointMaterial'
        if materialName in bpy.data.materials:
            bpy.context.object.data.materials.append(bpy.data.materials[materialName])
        else:
            print('NO MATERIAL IN LIBRARY WITH NAME ' + materialName)

    #create a mesh for each surface
    for surface in surfaceList:

        newMesh = bpy.data.meshes.new('SURFACE')
        if (not surface.faces):
            newMesh.from_pydata(surface.points,surface.edges,[])
        else:
            newMesh.from_pydata(surface.points,[],surface.faces)

        newMesh.update()
        newObj = bpy.data.objects.new('SURFACE',newMesh)

        #The necessary materials are created in the createMaterials function
        element = ''.join(i for i in surface.A if not i.isdigit())
        materialName = element + '-Surface_Material'
        if materialName in bpy.data.materials:
            newObj.data.materials.append(bpy.data.materials[materialName])
        else:
            print('NO MATERIAL IN LIBRARY WITH NAME ' + materialName)

        bpy.context.scene.objects.link(newObj)

    #create a polygon curve for each AIL

    #this creates a single bezier circle to give the AILs uniform thickness
    if len(lineList) != 0:
         bpy.ops.curve.primitive_bezier_circle_add()
         bpy.context.scene.objects.active = bpy.data.objects['BezierCircle']
         bpy.context.object.name = 'AIL-BevelCircle'
         bpy.ops.transform.resize(value=(0.25,0.25,0.25))

    #this creates all the lines
    for line in lineList:

        weight = 1 #all points on curve have same weight
        cList = line.points
        curveData = bpy.data.curves.new(name=line.A + '-' + line.B, type='CURVE')
        curveData.dimensions = '3D'

        objectData = bpy.data.objects.new('ObjCurve',curveData)
        objectData.location = (0,0,0)
        objectData.data.materials.append(bpy.data.materials['AIL_Material'])
        objectData.data.bevel_object = bpy.data.objects['AIL-BevelCircle']
        bpy.context.scene.objects.link(objectData)

        polyLine = curveData.splines.new('POLY')
        polyLine.points.add(len(cList)-1)
        for num in range(len(cList)):
            x,y,z = cList[num]
            polyLine.points[num].co = (x,y,z,weight)

    #This is a hack for the GVF - FIX IT
    bpy.ops.curve.primitive_bezier_circle_add()
    bpy.context.scene.objects.active = bpy.data.objects['BezierCircle']
    bpy.context.object.name = 'GVF-BevelCircle'
    bpy.ops.transform.resize(value=(0.25,0.25,0.25))

    for gvf in gvfList:

        #create a line for each gradient path in the gradient vector field
        for line in gvf.lines:
            weight = 1
            cList = line.points
            curveData = bpy.data.curves.new(name=gvf.A + '-GP', type='CURVE')
            curveData.dimensions = '3D'

            objectData = bpy.data.objects.new('ObjCurve',curveData)
            objectData.location = (0,0,0)
            objectData.data.materials.append(bpy.data.materials[gvf.A + '-CriticalPointMaterial'])
            objectData.data.bevel_object = bpy.data.objects['GVF-BevelCircle']
            bpy.context.scene.objects.link(objectData)

            polyLine = curveData.splines.new('POLY')
            polyLine.points.add(len(cList)-1)
            for num in range(len(cList)):
                x,y,z = cList[num]
                polyLine.points[num].co = (x,y,z,weight)

# This function creates a material for the given type of critical point 
# called element-CritPointColor
# This defines the default material for a CP other than its diffuse color
def createAtomMaterial(color,element):

    mat = bpy.data.materials.new(element + '-CriticalPointMaterial')
    mat.diffuse_color = color
    mat.diffuse_shader = 'LAMBERT'
    mat.diffuse_intensity = 1.0
    mat.specular_color = (1,1,1)
    mat.specular_shader = 'COOKTORR'
    mat.specular_intensity = 0.5
    mat.alpha = 1
    mat.ambient = 1
    mat.type = 'WIRE'

#Create a default material for the surfaces around a given element
# and is different to the CP material for flexibility
def createSurfaceMaterial(color,element):

    mat = bpy.data.materials.new(element + '-Surface_Material')
    mat.diffuse_color = color
    mat.diffuse_shader = 'LAMBERT'
    mat.diffuse_intensity = 1.0
    mat.specular_color = (1,1,1)
    mat.specular_shader = 'COOKTORR'
    mat.specular_intensity = 0.5
    mat.alpha = 1
    mat.ambient = 1

#Create a default material for rendering all AILs
def createAILMaterial():

    mat = bpy.data.materials.new('AIL_Material')
    mat.diffuse_color = (0.0, 0.0, 0.0)
    mat.diffuse_shader = 'LAMBERT'
    mat.diffuse_intensity = 1.0
    mat.specular_color = (1,1,1)
    mat.specular_shader = 'COOKTORR'
    mat.specular_intensity = 0.5
    mat.alpha = 1
    mat.ambient = 1

#def setupUI():

    #bpy.context.space_data.display_mode = 'GROUPS'

# This function sets up default render options, lights, camera to match the Morphy GUI
def setupWorld(sphereList):

    #This is where anything about the scene can be set, render options, lighting, camera and such
    cam = bpy.data.cameras.new("Cam")
    cam.clip_end = 1000.0
    center = findCenter(sphereList) # this should be done outside this function and passed in
    radius = computeRadius(sphereList)
    center[2] += (4.0 * radius)
    cam_ob = bpy.data.objects.new("Cam", cam)
    cam_ob.location=center
    bpy.context.scene.objects.link(cam_ob)

    rad45 = 45.0*(3.141519265359/180.0)
    rad90 = 90.0*(3.141519265359/180.0)
    sin45 = math.sin(rad45)

    #Now the lighting of the scene
    # Must create spotlight for key light at camera position, pointing in camera direction
    bpy.ops.object.lamp_add(type='SPOT',location=cam_ob.location)
    # move to the left (-ve x-direction), +ve along z and +ve along y
    x = -center[2]*sin45
    y = radius
    z = center[2]*sin45
    bpy.context.active_object.location = (x, y, z)

    angle = rad90 - math.atan(abs(x)/abs(y)) 
    bpy.context.active_object.rotation_euler = mathutils.Euler((0.0,-rad45,-angle),'XYZ')

    bpy.context.active_object.data.distance = center[2]
    bpy.context.active_object.data.energy = 15
    bpy.context.active_object.data.spot_size = 1.0 # rads!

    # and repeat this for the fill light, move in +ve x-direction. +ve along z and +ve y-direction
    # and light should be weaker

    bpy.ops.object.lamp_add(type='SPOT',location=cam_ob.location)

    x = center[2]*sin45
    y = radius
    z = x
    bpy.context.active_object.location = (x, y, z)

    angle = rad90 - math.atan(abs(x)/abs(y)) 
    bpy.context.active_object.rotation_euler = mathutils.Euler((0.0,rad45,angle),'XYZ')

    bpy.context.active_object.data.distance = center[2]
    bpy.context.active_object.data.energy = 5
    bpy.context.active_object.data.spot_size = 1.0 # rads!

    # and now the rim light
    bpy.ops.object.lamp_add(type='SPOT',location=cam_ob.location)
    bpy.context.active_object.location.z = -4.0*radius
    bpy.context.active_object.rotation_euler = mathutils.Euler((3.141519265359,0.0,0.0),'XYZ')

    bpy.context.active_object.data.distance = center[2]
    bpy.context.active_object.data.energy = 5
    bpy.context.active_object.data.spot_size = 1.0 # rads!
    
    #Lights are done, move on to render settings

    bpy.context.scene.render.resolution_x = 1000
    bpy.context.scene.render.resolution_y = 1000    
    bpy.context.scene.render.resolution_percentage = 50

    bpy.context.scene.render.use_antialiasing = True
    bpy.context.scene.render.antialiasing_samples = '8'
    bpy.context.scene.render.use_full_sample = True
    bpy.context.scene.render.pixel_filter_type = 'MITCHELL' #GAUSSIAN|CATMULLROM|CUBIC|QUADRATIC|TENT|BOX
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.image_settings.color_depth = '16'
    bpy.context.scene.render.image_settings.compression = 0

    #Provide light coming from all directions using the ambient param of materials
    #Also set the light energy and colour source. Turned off in favour of 3-point lights!
    #bpy.context.scene.world.light_settings.use_environment_light = True
    #bpy.context.scene.world.light_settings.environment_energy = 0.65
    #bpy.context.scene.world.light_settings.environment_color = 'PLAIN' #|SKY_COLOR | SKY_TEXTURE

    #set the background to be plain and flat RGB
    bpy.context.scene.world.horizon_color = (0.05, 0.20, 0.35)

    #set the AO colour to outdoor midday
    #bpy.context.scene.world.ambient_color = (0.90, 0.90, 0.80)
    #bpy.context.scene.world.light_settings.use_ambient_occlusion = True
    #bpy.context.scene.world.light_settings.ao_factor = 1.00
    #bpy.context.scene.world.light_settings.ao_blend_type = 'MULTIPLY' #ADD

    #Set up the quality of the ambient, indirect and AO
    #Turn ray-tracing on for AO and env lighting
    bpy.context.scene.render.use_raytrace = True
    bpy.context.scene.world.light_settings.gather_method = 'RAYTRACE'
    bpy.context.scene.world.light_settings.samples = 6

# Find the center of the distribution of critical points
def findCenter(sphereList):

    x_total = 0.0
    y_total = 0.0
    z_total = 0.0

    for cp in sphereList:
        x_total += cp.position[0]
        y_total += cp.position[1]
        z_total += cp.position[2]

    N = len(sphereList)
    x_origin = x_total / N
    y_origin = y_total / N
    z_origin = z_total / N

    return mathutils.Vector((float(x_origin),float(y_origin),float(z_origin)))

# Get the radius of a sphere containing all the critical point objects
def computeRadius(sphereList):

    max = -100000

    center = findCenter(sphereList)
    for cp in sphereList:
        position = cp.position - center
        r = math.sqrt(position[0]*position[0] + position[1]*position[1] + position[2]*position[2])

        if position[0] > max:
            max = position[0]

    return max

#This function creates a single material for each type of CP in the scene
def createMaterials(sphereList):

    elementColors = defineColors()
    #create the necessary set of element colors for this topology
    createdList = [] #list of the nuclear types created so far
    for cp in sphereList:
        #check the material for this sphere hasn't been made already
        duplicate = False
        for element in createdList:
            if cp.type == element:
                duplicate = True
                break

        #and if it has NOT then make it
        if duplicate == False:
            #create a new material
            createAtomMaterial(elementColors[cp.type],cp.type)
            createSurfaceMaterial(elementColors[cp.type],cp.type)
            createdList.append(cp.type)

    createAILMaterial()

if __name__ == "main":
 register()

#For Debugging as text script
#register()

#Info for installed Add-On
bl_info = \
{
"name"        : "QCT4Blender",
"author"      : "Matthew J L Mills <mjohnmills@gmail.com>",
"version"     : (0, 0, 0),
"blender"     : (2, 75, 0),
"location"    : "View 3D > Object Mode > Tool Shelf",
"description" : "Import and manipulate a QCT .top File",
"warning"     : "",
"wiki_url"    : "",
"tracker_url" : "",
"category"    : "Add Mesh",
}
