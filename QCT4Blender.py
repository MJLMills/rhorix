import xml.etree.ElementTree as ET
import bpy
import mathutils

#These objects must be read from the .top file, and then
#converted to blender data objects so that they persist on 
#saving the blender file.

sphereList = []    # list of CriticalPoint objects
lineList = []      # list of Line objects
surfaceList = []   # list of Surface objects

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class CriticalPoint():

    def __init__(self, type, rank, signature, position): #this is called on instantiation of the class
        self.type = type
        self.rank = rank
        self.signature = signature
        self.position = position

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class Line():

    def __init__(self, A, B, points):
        self.A = A
        self.B = B
        #points is a list of Vector objects - one for each point on the line
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class Surface():

    def __init__(self, A, points, edges):
        self.A = A
        #points is a list of vector objects - one for each point on the surface
        self.points = points
        self.edges = edges

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class QCTBlender(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label = "Import Topology"
    filter_glob = bpy.props.StringProperty(default="*.top", options={'HIDDEN'}) 
    
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4B: Opening File " + self.filepath)
        #First create the object representation of the QCT in the .top file
        readTopology(self.filepath)
        #Create all necessary default materials
        createMaterials()
        #Create the blender data rep of the QCT and assign materials
        #Anything created here is persistent, anything not converted to blender data is lost
        createBlenderObjects()
        #Setup the environment in which the QCT resides
        setupWorld()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

#*#*#*#*#*#*#*#*#*#* SCRIPT FUNCTION DEFINITIONS

def menu_function(self, context):
    self.layout.operator(QCTBlender.bl_idname, text="Quantum Chemical Topology (.top)")

def register():
    print("QCT4B: Registering Operator Class")
    print("QCT4B: Use Operator \'Import Topology\' or File -> Import -> \.top to Invoke")
    bpy.utils.register_class(QCTBlender)
    bpy.types.INFO_MT_file_import.append(menu_function)
 
def unregister():
    print("QCT4B: Deregistering Operator Class")
    bpy.utils.unregister_class(QCTBlender)
    bpy.utils.INFO_MT_file_import.remove(menu_function)

def readTopology(filepath):

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
            type = topologicalObject.find('type').text
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

                A = topologicalObject.find('A').text
                B = topologicalObject.find('B').text
                line = Line(A,B,vectorList)
                lineList.append(line)

            elif topologicalObject.tag == 'SURFACE':

                A = topologicalObject.find('A').text

                edgeList = []
                for edge in topologicalObject.findall('edge'):
                    A = edge.find('A').text
                    B = edge.find('B').text
                    newEdge = [int(A),int(B)]
                    edgeList.append(newEdge)

                surface = Surface(A,vectorList,edgeList)
                surfaceList.append(surface)

def createBlenderObjects():

    #create a UV sphere for each CP
    for cp in sphereList:

        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cp.position)

        #The necessary materials are created in the createMaterials function
        materialName = cp.type + '-CritPointColor'
        if materialName in bpy.data.materials:
            bpy.context.object.data.materials.append(bpy.data.materials[materialName])
        else:
            print('NO MATERIAL IN LIBRARY WITH NAME ' + materialName)

    #create a mesh for each surface
    for surface in surfaceList:

        newMesh = bpy.data.meshes.new('SURFACE')
        newMesh.from_pydata(surface.points,surface.edges,[])
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
    for line in lineList:

        weight = 1 #all points on curve have same weight
        cList = line.points
        curveData = bpy.data.curves.new(name=line.A + '-' + line.B, type='CURVE')
        curveData.dimensions = '3D'

        objectData = bpy.data.objects.new('ObjCurve',curveData)
        objectData.location = (0,0,0)
        objectData.data.materials.append(bpy.data.materials['AIL_Material'])
        bpy.context.scene.objects.link(objectData)

        polyLine = curveData.splines.new('POLY')
        polyLine.points.add(len(cList)-1)
        for num in range(len(cList)):
            x,y,z = cList[num]
            polyLine.points[num].co = (x,y,z,weight)

#This function creates a material for the given critical point called element-CritPointColor
#This defines the default material for a CP other than its diffuse color
def createAtomMaterial(color,element):

    mat = bpy.data.materials.new(element + '-CritPointColor')
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

def setupWorld():
    #This is where anything about the scene can be set, render options, lighting, camera and such
    print("TODO: SETUP WORLD")

#This function creates a single material for each CP in the scene
def createMaterials():

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
register()

#Info for installed Add-On
bl_info = \
{
"name"        : "QCT4Blender",
"author"      : "Matthew J L Mills <mjohnmills@gmail.com>",
"version"     : (0, 0, 0),
"blender"     : (2, 69, 0),
"location"    : "View 3D > Object Mode > Tool Shelf",
"description" : "Import a QCT .top File",
"warning"     : "",
"wiki_url"    : "",
"tracker_url" : "",
"category"    : "Add Mesh",
}

def defineColors():
    #THESE ARE BORROWED FROM PYMOL - http://www.pymolwiki.org/index.php/Color_Values
    elementColors = \
    {
    "bcp"   :    ( 1.000000000,  0.000000000,  0.000000000),
    "ccp"   :    ( 0.000000000,  1.000000000,  0.000000000),
    "rcp"   :    ( 0.000000000,  0.000000000,  1.000000000),
    "Ac"    :    ( 0.439215686,  0.670588235,  0.980392157),
    "Al"    :    ( 0.749019608,  0.650980392,  0.650980392),
    "Am"    :    ( 0.329411765,  0.360784314,  0.949019608),
    "Sb"    :    ( 0.619607843,  0.388235294,  0.709803922),
    "Ar"    :    ( 0.501960784,  0.819607843,  0.890196078),
    "As"    :    ( 0.741176471,  0.501960784,  0.890196078),
    "At"    :    ( 0.458823529,  0.309803922,  0.270588235),
    "Ba"    :    ( 0.000000000,  0.788235294,  0.000000000),
    "Bk"    :    ( 0.541176471,  0.309803922,  0.890196078),
    "Be"    :    ( 0.760784314,  1.000000000,  0.000000000),
    "Bi"    :    ( 0.619607843,  0.309803922,  0.709803922),
    "Bh"    :    ( 0.878431373,  0.000000000,  0.219607843),
    "B"     :    ( 1.000000000,  0.709803922,  0.709803922),
    "Br"    :    ( 0.650980392,  0.160784314,  0.160784314),
    "Cd"    :    ( 1.000000000,  0.850980392,  0.560784314),
    "Ca"    :    ( 0.239215686,  1.000000000,  0.000000000),
    "Cf"    :    ( 0.631372549,  0.211764706,  0.831372549),
    "C"     :    ( 0.200000000,  1.000000000,  0.200000000),
    "Ce"    :    ( 1.000000000,  1.000000000,  0.780392157),
    "Cs"    :    ( 0.341176471,  0.090196078,  0.560784314),
    "Cl"    :    ( 0.121568627,  0.941176471,  0.121568627),
    "Cr"    :    ( 0.541176471,  0.600000000,  0.780392157),
    "Co"    :    ( 0.941176471,  0.564705882,  0.627450980),
    "Cu"    :    ( 0.784313725,  0.501960784,  0.200000000),
    "Cm"    :    ( 0.470588235,  0.360784314,  0.890196078),
    "Db"    :    ( 0.819607843,  0.000000000,  0.309803922),
    "Dy"    :    ( 0.121568627,  1.000000000,  0.780392157),
    "Es"    :    ( 0.701960784,  0.121568627,  0.831372549),
    "Er"    :    ( 0.000000000,  0.901960784,  0.458823529),
    "Eu"    :    ( 0.380392157,  1.000000000,  0.780392157),
    "Fm"    :    ( 0.701960784,  0.121568627,  0.729411765),
    "F"     :    ( 0.701960784,  1.000000000,  1.000000000),
    "Fr"    :    ( 0.258823529,  0.000000000,  0.400000000),
    "Gd"    :    ( 0.270588235,  1.000000000,  0.780392157),
    "Ga"    :    ( 0.760784314,  0.560784314,  0.560784314),
    "Ge"    :    ( 0.400000000,  0.560784314,  0.560784314),
    "Au"    :    ( 1.000000000,  0.819607843,  0.137254902),
    "Hf"    :    ( 0.301960784,  0.760784314,  1.000000000),
    "Hs"    :    ( 0.901960784,  0.000000000,  0.180392157),
    "He"    :    ( 0.850980392,  1.000000000,  1.000000000),
    "Ho"    :    ( 0.000000000,  1.000000000,  0.611764706),
    "H"     :    ( 0.900000000,  0.900000000,  0.900000000),
    "In"    :    ( 0.650980392,  0.458823529,  0.450980392),
    "I"     :    ( 0.580392157,  0.000000000,  0.580392157),
    "Ir"    :    ( 0.090196078,  0.329411765,  0.529411765),
    "Fe"    :    ( 0.878431373,  0.400000000,  0.200000000),
    "Kr"    :    ( 0.360784314,  0.721568627,  0.819607843),
    "La"    :    ( 0.439215686,  0.831372549,  1.000000000),
    "Lr"    :    ( 0.780392157,  0.000000000,  0.400000000),
    "Pb"    :    ( 0.341176471,  0.349019608,  0.380392157),
    "Li"    :    ( 0.800000000,  0.501960784,  1.000000000),
    "Lu"    :    ( 0.000000000,  0.670588235,  0.141176471),
    "Mg"    :    ( 0.541176471,  1.000000000,  0.000000000),
    "Mn"    :    ( 0.611764706,  0.478431373,  0.780392157),
    "Mt"    :    ( 0.921568627,  0.000000000,  0.149019608),
    "Md"    :    ( 0.701960784,  0.050980392,  0.650980392),
    "Hg"    :    ( 0.721568627,  0.721568627,  0.815686275),
    "Mo"    :    ( 0.329411765,  0.709803922,  0.709803922),
    "Nd"    :    ( 0.780392157,  1.000000000,  0.780392157),
    "Ne"    :    ( 0.701960784,  0.890196078,  0.960784314),
    "Np"    :    ( 0.000000000,  0.501960784,  1.000000000),
    "Ni"    :    ( 0.313725490,  0.815686275,  0.313725490),
    "Nb"    :    ( 0.450980392,  0.760784314,  0.788235294),
    "N"     :    ( 0.200000000,  0.200000000,  1.000000000),
    "No"    :    ( 0.741176471,  0.050980392,  0.529411765),
    "Os"    :    ( 0.149019608,  0.400000000,  0.588235294),
    "O"     :    ( 1.000000000,  0.300000000,  0.300000000),
    "Pd"    :    ( 0.000000000,  0.411764706,  0.521568627),
    "P"     :    ( 1.000000000,  0.501960784,  0.000000000),
    "Pt"    :    ( 0.815686275,  0.815686275,  0.878431373),
    "Pu"    :    ( 0.000000000,  0.419607843,  1.000000000),
    "Po"    :    ( 0.670588235,  0.360784314,  0.000000000),
    "K"     :    ( 0.560784314,  0.250980392,  0.831372549),
    "Pr"    :    ( 0.850980392,  1.000000000,  0.780392157),
    "Pm"    :    ( 0.639215686,  1.000000000,  0.780392157),
    "Pa"    :    ( 0.000000000,  0.631372549,  1.000000000),
    "Ra"    :    ( 0.000000000,  0.490196078,  0.000000000),
    "Rn"    :    ( 0.258823529,  0.509803922,  0.588235294),
    "Re"    :    ( 0.149019608,  0.490196078,  0.670588235),
    "Rh"    :    ( 0.039215686,  0.490196078,  0.549019608),
    "Rb"    :    ( 0.439215686,  0.180392157,  0.690196078),
    "Ru"    :    ( 0.141176471,  0.560784314,  0.560784314),
    "Rf"    :    ( 0.800000000,  0.000000000,  0.349019608),
    "Sm"    :    ( 0.560784314,  1.000000000,  0.780392157),
    "Sc"    :    ( 0.901960784,  0.901960784,  0.901960784),
    "Sg"    :    ( 0.850980392,  0.000000000,  0.270588235),
    "Se"    :    ( 1.000000000,  0.631372549,  0.000000000),
    "Si"    :    ( 0.941176471,  0.784313725,  0.627450980),
    "Ag"    :    ( 0.752941176,  0.752941176,  0.752941176),
    "Na"    :    ( 0.670588235,  0.360784314,  0.949019608),
    "Sr"    :    ( 0.000000000,  1.000000000,  0.000000000),
    "S"     :    ( 0.900000000,  0.775000000,  0.250000000),
    "Ta"    :    ( 0.301960784,  0.650980392,  1.000000000),
    "Tc"    :    ( 0.231372549,  0.619607843,  0.619607843),
    "Te"    :    ( 0.831372549,  0.478431373,  0.000000000),
    "Tb"    :    ( 0.188235294,  1.000000000,  0.780392157),
    "Tl"    :    ( 0.650980392,  0.329411765,  0.301960784),
    "Th"    :    ( 0.000000000,  0.729411765,  1.000000000),
    "Tm"    :    ( 0.000000000,  0.831372549,  0.321568627),
    "Sn"    :    ( 0.400000000,  0.501960784,  0.501960784),
    "Ti"    :    ( 0.749019608,  0.760784314,  0.780392157),
    "W"     :    ( 0.129411765,  0.580392157,  0.839215686),
    "U"     :    ( 0.000000000,  0.560784314,  1.000000000),
    "V"     :    ( 0.650980392,  0.650980392,  0.670588235),
    "Xe"    :    ( 0.258823529,  0.619607843,  0.690196078),
    "Yb"    :    ( 0.000000000,  0.749019608,  0.219607843),
    "Y"     :    ( 0.580392157,  1.000000000,  1.000000000),
    "Zn"    :    ( 0.490196078,  0.501960784,  0.690196078),
    "Zr"    :    ( 0.580392157,  0.878431373,  0.878431373),
    }
    return elementColors
