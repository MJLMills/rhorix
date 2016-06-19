# Matthew J L Mills - RhoRix Main Program
# www.mjlmills.com/rhorix

import xml.etree.ElementTree as ET
import bpy
import mathutils
import math

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

#This encapsulates the 3D representation of the topology.
class Topology3D():
    
    def __init__(self,sphereList,lineList,surfaceList,gvfList):
        self.sphereList = sphereList   # list of CriticalPoint objects
        self.lineList = lineList       # list of Line objects
        self.surfaceList = surfaceList # list of Surface objects
        self.gvfList = gvfList         # list of all GradientVectorField objects

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

# A critical point is a topological object with a single vector member
# This does not need to change.
class CriticalPoint():

    def __init__(self, type, rank, signature, position):
        self.type = type
        self.rank = rank
        self.signature = signature
        self.position = position

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

# A line is a set of vectors to be connected
# NOTES - A line should be just a set of vectors. Topological objects are made of lines, such as AILs and GVF GPs.
# The labelling should be done at a higher level, in an AIL or GP object.
class Line():

    def __init__(self, A, B, points):
        self.A = A
        self.B = B
        #points is a list of Vector objects - one for each point on the line
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

# A surface is a set of points that is triangulated
# This also needs to be abstracted one lower, as there are different kinds of surface (IAS, constant cap)
# which may belong to multiple atoms (i.e. an IAS borders 2 nuclei)
class Surface():

    def __init__(self, A, points, edges, faces):
        self.A = A
        #points is a list of vector objects - one for each point on the surface
        self.points = points
        self.edges = edges
        self.faces = faces

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

# A gradient vector field is a set of GPs and a label for the nucleus each originates at.
# Might be better to have a GP class at the bottom of the hierarchy rather than a line?
class GradientVectorField():

    def __init__(self, A, lines):
        self.A = A
        self.lines = lines

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (OPERATOR)

class QCTBlender(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label = "Import Topology"
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'}) 
    
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4B: Opening File " + self.filepath)
        #First create the object representation of the QCT in the .top file
        topology = readTopology(self.filepath)
        #Create all necessary default materials
        createMaterials(topology.sphereList)
        #Create the blender data rep of the QCT and assign materials
        #Anything created herein is persistent; anything not converted to blender data is lost on save/open
        createBlenderObjects(topology)
        #Setup the environment in which the QCT resides (camera,lights,etc.)
        setupWorld(topology.sphereList)
        setupUI()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (OPERATOR)

class SelectNuclei(bpy.types.Operator):

    bl_idname = "qct.select_nuclei"
    bl_label = "Select Nuclei"

    def invoke(self,context,event):
        for object in bpy.data.objects:
            object.selected = False
        bpy.ops.object.select_pattern(pattern="CP")
        return {'FINISHED'}

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (OPERATOR)

class RenderStereo(bpy.types.Operator):

    bl_idname = "qct.render_stereo"
    bl_label = "Render Stereo"

    def invoke(self,context,event):
        print("Render Stereo Clicked")
        bpy.context.scene.render.use_multiview = True
        bpy.context.scene.render.views_format = 'STEREO_3D'
        for object in bpy.data.objects:
            object.selected = False
        bpy.ops.object.select_pattern(pattern="Cam")
        bpy.context.object.data.stereo.convergence_mode = 'OFFAXIS'
        bpy.context.object.data.stereo.convergence_distance = 1.95
        bpy.context.object.data.stereo.interocular_distance = 0.065

        #This should check if stereo is turned on, then turn it off
        if (False):
            bpy.context.scene.render.use_multiview = False

        return {'FINISHED'}

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION (GUI)

class QCTPanel(bpy.types.Panel):
    
    bl_region_type = "TOOLS"    #Appear in the toolshelf (T)
    bl_space_type = "VIEW_3D"   #when the 3D view
    bl_context = "objectmode"   #is in object mode.
    bl_category = "Tools"      #Appear in the Create tab of the toolshelf.
    bl_label = "RhoRix Controls"

    def draw(self,context):
        uiColumn = self.layout.column(align=True)
        uiColumn.prop(context.scene, "read_simple_topology")
        uiColumn.operator("qct.import_topology", text="Import Topology")
        uiColumn.operator("qct.select_nuclei", text="Select Nuclei")
        uiColumn.operator("qct.render_stereo", text="Render Stereo")

#*#*#*#*#*#*#*#*#*#* SCRIPT FUNCTION DEFINITIONS

def menu_function(self, context):
    self.layout.operator(QCTBlender.bl_idname, text="Quantum Chemical Topology (.top)")

def register():
    print("QCT4B: Registering Operator Classes")
    print("QCT4B: Use Operator \'Import Topology\' or File -> Import -> \.top to Invoke")
    bpy.utils.register_class(QCTBlender)
    bpy.types.INFO_MT_file_import.append(menu_function)
    bpy.utils.register_class(SelectNuclei)
    bpy.utils.register_class(RenderStereo)
    bpy.utils.register_class(QCTPanel)

    bpy.types.Scene.read_simple_topology = bpy.props.BoolProperty \
      (
        name = "Simple Topology",
        description = "Only read CPs and AILs",
        default = False
      )
 
def unregister():
    print("QCT4B: Deregistering Operator Class")
    bpy.utils.unregister_class(QCTBlender)
    bpy.utils.INFO_MT_file_import.remove(menu_function)
    bpy.utils.unregister_class(SelectNuclei)
    bpy.utils.unregister_class(RenderStereo)
    bpy.utils.unregister_class(QCTPanel)
    del bpy.types.Scene.read_simple_topology

def readTopology(filepath):

    sphereList = []
    lineList = []
    surfaceList = []
    gvfList = []

    #given an open topology file create all the corresponding python objects
    #this has to be more careful in case of malformed files - dtd maybe?
    topologyTree = ET.parse(filepath)
    topologyRoot = topologyTree.getroot()
    if topologyRoot.tag != 'topology':
        print('readTopology\: Not a Valid Topology File')
        exit(1)

    for topologicalObject in topologyRoot:

        if topologicalObject.tag == 'CP':

            #add a CP to the scene with the appropriate data
            type = topologicalObject.find('type').text.lower()
            rank = topologicalObject.find('rank').text
            signature = topologicalObject.find('signature').text
            x = topologicalObject.find('x').text
            y = topologicalObject.find('y').text
            z = topologicalObject.find('z').text
            #convert x,y,z to a position vector - has to be a less verbose way?
            positionVector = mathutils.Vector((float(x),float(y),float(z)))
            cp = CriticalPoint(type,rank,signature,positionVector)
            sphereList.append(cp)

        elif topologicalObject.tag == 'LINE' or topologicalObject.tag == 'SURFACE':

            #create a list of Vectors from the file data
            vectorList = []
            for point in topologicalObject.findall('vector'):
                x = point.find('x').text
                y = point.find('y').text
                z = point.find('z').text
                pointVector = mathutils.Vector((float(x),float(y),float(z)))
                vectorList.append(pointVector)

            if topologicalObject.tag == 'LINE':

                A = topologicalObject.find('A').text.lower()
                B = topologicalObject.find('B').text.lower()
                line = Line(A,B,vectorList)
                lineList.append(line)

            elif topologicalObject.tag == 'SURFACE':

                A = topologicalObject.find('A').text.lower()

                edgeList = []
                for edge in topologicalObject.findall('edge'):
                    a = edge.find('A').text
                    b = edge.find('B').text
                    newEdge = [int(a),int(b)]
                    edgeList.append(newEdge)

                faceList = []
                for face in topologicalObject.findall('face'):
                    a = face.find('A').text
                    b = face.find('B').text
                    c = face.find('C').text
                    newFace = [int(a),int(b),int(c)]
                    faceList.append(newFace)

                surface = Surface(A,vectorList,edgeList,faceList)
                surfaceList.append(surface)

        elif topologicalObject.tag == 'GVF':

          A = topologicalObject.find('label').text.lower()
          lineList = []
          for gp in topologicalObject.findall('line'):
              vectorList = []
              for point in gp.findall('vector'):
                  x = point.find('x').text
                  y = point.find('y').text
                  z = point.find('z').text
                  pointVector = mathutils.Vector((float(x),float(y),float(z)))
                  vectorList.append(pointVector)
              line = Line('H','H',vectorList)
              lineList.append(line)

          gvf = GradientVectorField(A,lineList)
          gvfList.append(gvf)

    topology = Topology3D(sphereList,lineList,surfaceList,gvfList)
    return topology

def createBlenderObjects(topology):

    sphereList = topology.sphereList
    lineList = topology.lineList
    surfaceList = topology.surfaceList
    gvfList = topology.gvfList

    if (len(sphereList) > 0):
      bpy.ops.group.create(name="Critical_Points")    

    elementRadii = defineRadii()
    #create a UV sphere for each CP
    for cp in sphereList:

        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cp.position,size=0.1*elementRadii[cp.type],segments=32,ring_count=16)
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

#This function creates a material for the given critical point called element-CritPointColor
#This defines the default material for a CP other than its diffuse color
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

#Create a default material for the surfaces around a given element - different to critpoints for flexibility
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

#Create a default material for rendering AILs
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

def setupUI():

    bpy.context.space_data.display_mode = 'GROUPS'

def setupWorld(sphereList):

    #This is where anything about the scene can be set, render options, lighting, camera and such
    cam = bpy.data.cameras.new("Cam")
    cam.clip_end = 1000.0
    center = findCenter(sphereList)
    radius = computeRadius(sphereList)
    center[2] += (4.0 * radius)
    cam_ob = bpy.data.objects.new("Cam", cam)
    cam_ob.location=center
    bpy.context.scene.objects.link(cam_ob)

    bpy.context.scene.render.resolution_x = 1000
    bpy.context.scene.render.resolution_y = 1000    
    bpy.context.scene.render.resolution_percentage = 50

    bpy.context.scene.render.use_antialiasing = True
    bpy.context.scene.render.antialiasing_samples = '8'
    bpy.context.scene.render.use_full_sample = True
    bpy.context.scene.render.pixel_filter_type = 'MITCHELL' #GAUSSIAN|CATMULLROM|CUBIC|QUADRATIC|TENT|BOX
    #The following are useful but do not appear to work
    #bpy.context.scene.render.file_format = 'PNG'
    #bpy.context.scene.render.color_depth = '16'
    #bpy.context.scene.render.compression = 0

    #Provide light coming from all directions using the ambient param of materials
    #Also set the light energy and colour source.
    bpy.context.scene.world.light_settings.use_environment_light = True
    bpy.context.scene.world.light_settings.environment_energy = 0.65
    bpy.context.scene.world.light_settings.environment_color = 'PLAIN' #|SKY_COLOR | SKY_TEXTURE

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

def computeRadius(sphereList):

    max = -100000

    center = findCenter(sphereList)
    for cp in sphereList:
        position = cp.position - center
        r = math.sqrt(position[0]*position[0] + position[1]*position[1] + position[2]*position[2])

        if position[0] > max:
            max = position[0]

    return max

#This function creates a single material for each CP in the scene
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

def defineRadii():
    #Initial values taken from the old Java GUI - if not present, radius = 2.0
    elementRadii = \
    {
    "bcp" : 0.75,
    "rcp" : 0.75,
    "ccp" : 0.75,
    "ag"  : 1.72,
    "ar"  : 1.88,
    "as"  : 1.85,
    "au"  : 1.66,
    "b"   : 2.00,
    "br"  : 1.85,
    "c"   : 1.70,
    "cd"  : 1.58,
    "cl"  : 1.75,
    "cu"  : 1.40,
    "f"   : 1.47,
    "fe"  : 2.00,
    "ga"  : 1.87,
    "h"   : 1.20,
    "he"  : 1.40,
    "hg"  : 1.55,
    "i"   : 1.98,
    "in"  : 1.93,
    "k"   : 2.75,
    "kr"  : 2.02,
    "li"  : 1.82,
    "mg"  : 1.73,
    "n"   : 1.55,
    "na"  : 2.27,
    "ne"  : 1.54,
    "ni"  : 1.63,
    "o"   : 1.52,
    "p"   : 1.80,
    "pb"  : 2.02,
    "pd"  : 1.63,
    "pt"  : 1.72,
    "s"   : 1.80,
    "se"  : 1.90,
    "si"  : 2.10,
    "sn"  : 2.17,
    "te"  : 2.06,
    "tl"  : 1.96,
    "u"   : 1.86,
    "xe"  : 2.16,
    "zn"  : 1.39,
    }
    return elementRadii

def defineColors():
    #THESE ARE BORROWED FROM PYMOL - http://www.pymolwiki.org/index.php/Color_Values
    elementColors = \
    {
    "bcp"   :    ( 1.000000000,  0.000000000,  0.000000000),
    "ccp"   :    ( 0.000000000,  1.000000000,  0.000000000),
    "rcp"   :    ( 0.000000000,  0.000000000,  1.000000000),
    "ac"    :    ( 0.439215686,  0.670588235,  0.980392157),
    "al"    :    ( 0.749019608,  0.650980392,  0.650980392),
    "am"    :    ( 0.329411765,  0.360784314,  0.949019608),
    "sb"    :    ( 0.619607843,  0.388235294,  0.709803922),
    "ar"    :    ( 0.501960784,  0.819607843,  0.890196078),
    "as"    :    ( 0.741176471,  0.501960784,  0.890196078),
    "at"    :    ( 0.458823529,  0.309803922,  0.270588235),
    "ba"    :    ( 0.000000000,  0.788235294,  0.000000000),
    "bk"    :    ( 0.541176471,  0.309803922,  0.890196078),
    "be"    :    ( 0.760784314,  1.000000000,  0.000000000),
    "bi"    :    ( 0.619607843,  0.309803922,  0.709803922),
    "bh"    :    ( 0.878431373,  0.000000000,  0.219607843),
    "b"     :    ( 1.000000000,  0.709803922,  0.709803922),
    "br"    :    ( 0.650980392,  0.160784314,  0.160784314),
    "cd"    :    ( 1.000000000,  0.850980392,  0.560784314),
    "ca"    :    ( 0.239215686,  1.000000000,  0.000000000),
    "cf"    :    ( 0.631372549,  0.211764706,  0.831372549),
    "c"     :    ( 0.200000000,  1.000000000,  0.200000000),
    "ce"    :    ( 1.000000000,  1.000000000,  0.780392157),
    "cs"    :    ( 0.341176471,  0.090196078,  0.560784314),
    "cl"    :    ( 0.121568627,  0.941176471,  0.121568627),
    "cr"    :    ( 0.541176471,  0.600000000,  0.780392157),
    "co"    :    ( 0.941176471,  0.564705882,  0.627450980),
    "cu"    :    ( 0.784313725,  0.501960784,  0.200000000),
    "cm"    :    ( 0.470588235,  0.360784314,  0.890196078),
    "db"    :    ( 0.819607843,  0.000000000,  0.309803922),
    "dy"    :    ( 0.121568627,  1.000000000,  0.780392157),
    "es"    :    ( 0.701960784,  0.121568627,  0.831372549),
    "er"    :    ( 0.000000000,  0.901960784,  0.458823529),
    "eu"    :    ( 0.380392157,  1.000000000,  0.780392157),
    "fm"    :    ( 0.701960784,  0.121568627,  0.729411765),
    "f"     :    ( 0.701960784,  1.000000000,  1.000000000),
    "fr"    :    ( 0.258823529,  0.000000000,  0.400000000),
    "gd"    :    ( 0.270588235,  1.000000000,  0.780392157),
    "ga"    :    ( 0.760784314,  0.560784314,  0.560784314),
    "ge"    :    ( 0.400000000,  0.560784314,  0.560784314),
    "au"    :    ( 1.000000000,  0.819607843,  0.137254902),
    "hf"    :    ( 0.301960784,  0.760784314,  1.000000000),
    "hs"    :    ( 0.901960784,  0.000000000,  0.180392157),
    "he"    :    ( 0.850980392,  1.000000000,  1.000000000),
    "ho"    :    ( 0.000000000,  1.000000000,  0.611764706),
    "h"     :    ( 0.900000000,  0.900000000,  0.900000000),
    "in"    :    ( 0.650980392,  0.458823529,  0.450980392),
    "i"     :    ( 0.580392157,  0.000000000,  0.580392157),
    "ir"    :    ( 0.090196078,  0.329411765,  0.529411765),
    "fe"    :    ( 0.878431373,  0.400000000,  0.200000000),
    "kr"    :    ( 0.360784314,  0.721568627,  0.819607843),
    "la"    :    ( 0.439215686,  0.831372549,  1.000000000),
    "lr"    :    ( 0.780392157,  0.000000000,  0.400000000),
    "pb"    :    ( 0.341176471,  0.349019608,  0.380392157),
    "li"    :    ( 0.800000000,  0.501960784,  1.000000000),
    "lu"    :    ( 0.000000000,  0.670588235,  0.141176471),
    "mg"    :    ( 0.541176471,  1.000000000,  0.000000000),
    "mn"    :    ( 0.611764706,  0.478431373,  0.780392157),
    "mt"    :    ( 0.921568627,  0.000000000,  0.149019608),
    "md"    :    ( 0.701960784,  0.050980392,  0.650980392),
    "hg"    :    ( 0.721568627,  0.721568627,  0.815686275),
    "mo"    :    ( 0.329411765,  0.709803922,  0.709803922),
    "nd"    :    ( 0.780392157,  1.000000000,  0.780392157),
    "ne"    :    ( 0.701960784,  0.890196078,  0.960784314),
    "np"    :    ( 0.000000000,  0.501960784,  1.000000000),
    "ni"    :    ( 0.313725490,  0.815686275,  0.313725490),
    "nb"    :    ( 0.450980392,  0.760784314,  0.788235294),
    "n"     :    ( 0.200000000,  0.200000000,  1.000000000),
    "no"    :    ( 0.741176471,  0.050980392,  0.529411765),
    "os"    :    ( 0.149019608,  0.400000000,  0.588235294),
    "o"     :    ( 1.000000000,  0.300000000,  0.300000000),
    "pd"    :    ( 0.000000000,  0.411764706,  0.521568627),
    "p"     :    ( 1.000000000,  0.501960784,  0.000000000),
    "pt"    :    ( 0.815686275,  0.815686275,  0.878431373),
    "pu"    :    ( 0.000000000,  0.419607843,  1.000000000),
    "po"    :    ( 0.670588235,  0.360784314,  0.000000000),
    "k"     :    ( 0.560784314,  0.250980392,  0.831372549),
    "pr"    :    ( 0.850980392,  1.000000000,  0.780392157),
    "pm"    :    ( 0.639215686,  1.000000000,  0.780392157),
    "pa"    :    ( 0.000000000,  0.631372549,  1.000000000),
    "ra"    :    ( 0.000000000,  0.490196078,  0.000000000),
    "rn"    :    ( 0.258823529,  0.509803922,  0.588235294),
    "re"    :    ( 0.149019608,  0.490196078,  0.670588235),
    "rh"    :    ( 0.039215686,  0.490196078,  0.549019608),
    "rb"    :    ( 0.439215686,  0.180392157,  0.690196078),
    "ru"    :    ( 0.141176471,  0.560784314,  0.560784314),
    "rf"    :    ( 0.800000000,  0.000000000,  0.349019608),
    "sm"    :    ( 0.560784314,  1.000000000,  0.780392157),
    "sc"    :    ( 0.901960784,  0.901960784,  0.901960784),
    "sg"    :    ( 0.850980392,  0.000000000,  0.270588235),
    "se"    :    ( 1.000000000,  0.631372549,  0.000000000),
    "si"    :    ( 0.941176471,  0.784313725,  0.627450980),
    "ag"    :    ( 0.752941176,  0.752941176,  0.752941176),
    "na"    :    ( 0.670588235,  0.360784314,  0.949019608),
    "sr"    :    ( 0.000000000,  1.000000000,  0.000000000),
    "s"     :    ( 0.900000000,  0.775000000,  0.250000000),
    "ta"    :    ( 0.301960784,  0.650980392,  1.000000000),
    "tc"    :    ( 0.231372549,  0.619607843,  0.619607843),
    "te"    :    ( 0.831372549,  0.478431373,  0.000000000),
    "tb"    :    ( 0.188235294,  1.000000000,  0.780392157),
    "tl"    :    ( 0.650980392,  0.329411765,  0.301960784),
    "th"    :    ( 0.000000000,  0.729411765,  1.000000000),
    "tm"    :    ( 0.000000000,  0.831372549,  0.321568627),
    "sn"    :    ( 0.400000000,  0.501960784,  0.501960784),
    "ti"    :    ( 0.749019608,  0.760784314,  0.780392157),
    "w"     :    ( 0.129411765,  0.580392157,  0.839215686),
    "u"     :    ( 0.000000000,  0.560784314,  1.000000000),
    "v"     :    ( 0.650980392,  0.650980392,  0.670588235),
    "xe"    :    ( 0.258823529,  0.619607843,  0.690196078),
    "yb"    :    ( 0.000000000,  0.749019608,  0.219607843),
    "y"     :    ( 0.580392157,  1.000000000,  1.000000000),
    "zn"    :    ( 0.490196078,  0.501960784,  0.690196078),
    "zr"    :    ( 0.580392157,  0.878431373,  0.878431373),
    }
    return elementColors

