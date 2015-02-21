import xml.etree.ElementTree as ET
import bpy
import mathutils

sphereList = []  #list of CriticalPoint objects
lineList = []    #list of Line objects
surfaceList = [] #list of Surface objects

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
        #points is a list of Vector objects - one for each vertex
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class Surface():

    def __init__(self, A, points):
        self.A = A
        #points is a list of vector objects - one for each vertex
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class QCTBlender(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label = "Import Topology"
 
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4B: Opening File " + self.filepath)
        readTopology(self.filepath)
        createBlenderObjects()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

#*#*#*#*#*#*#*#*#*#* SCRIPT FUNCTION DEFINITIONS

def register():
    print("QCT4B: Registering Operator Class")
    print("QCT4B: Use Operator \'Import Topology\'")
    bpy.utils.register_class(QCTBlender)
 
def unregister():
    print("QCT4B: Deregistering Operator Class")
    bpy.utils.unregister_class(QCTBlender)

def readTopology(filepath):

    #given an open topology file create all the corresponding python objects
    topologyTree = ET.parse(filepath)
    topologyRoot = topologyTree.getroot()
    if topologyRoot.tag != 'topology':
        print('Not a Topology File')
        exit(1)

    for topologicalObject in topologyRoot:

        if topologicalObject.tag == 'CP':
            #add a CP to the scene with the appropriate data
            type = topologicalObject.find(type).text
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
                surface = Surface(A,vectorList)
                surfaceList.append(surface)

def createBlenderObjects():

    for cp in sphereList:

        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cp.position)

    for surface in surfaceList:

        newMesh = bpy.data.meshes.new('SURFACE')
        newMesh.from_pydata(surface.points,[],[])
        newMesh.update()
        newObj = bpy.data.objects.new('SURFACE',newMesh)
        bpy.context.scene.objects.link(newObj)

    for line in lineList:

        newMesh = bpy.data.meshes.new('LINE')
        newMesh.from_pydata(line.points,[],[])
        newMesh.update()
        newObj = bpy.data.objects.new('LINE',newMesh)
        bpy.context.scene.objects.link(newObj)


def createAtomMaterial(name):
    #name is the element of the atom
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (1,0,0) #look up the color from the element
    mat.diffuse_shader = 'LAMBERT'
    mat.diffuse_intensity = 1.0
    mat.specular_color = (1,1,1)
    mat.specular_shader = 'COOKTORR'
    mat.specular_intensity = 0.5
    mat.alpha = 1
    mat.ambient = 1

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
