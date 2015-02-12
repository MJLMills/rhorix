import xml.etree.ElementTree as ET
import bpy
import mathutils

cpList = [] #list of CrticalPoint objects
ailList = [] #list of AtomicInteractionLine objects
surfaceList = [] #list of Surface objects

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class CriticalPoint():

    def __init__(self, rank, signature, position): #this is called on instantiation of the class
        self.rank = rank
        self.signature = signature
        self.position = position

    def printOut(self): # just for debugging
        print('RANK:      ' + self.rank)
        print('SIGNATURE: ' + self.signature)
        print('POSITION:  ' + str(self.position.x) + ' ' + str(self.position.y) + ' ' + str(self.position.z))

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class AtomicInteractionLine():

    def __init__(self, points):
        #points is a list of Vector objects - one for each vertex
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class Surface():

    def __init__(self, points):
        #points is a list of vector objects - one for each vertex
        self.points = points

#*#*#*#*#*#*#*#*#*#*# CLASS DEFINITION

class QCTBlender(bpy.types.Operator):

    bl_idname = "qct.import_topology"
    bl_label = "Import Topology"
 
    filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
    def execute(self, context):
        print("QCT4Blender Executed")
        print("Opening File: " + self.filepath)
        readTopology(self.filepath)
        createBlenderObjects()
        return{'FINISHED'}
  
    def invoke(self, context, event):
        print("QCT4Blender Invoked")
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


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

#*#*#*#*#*#*#*#*#*#* SCRIPT FUNCTION DEFINITIONS

def register():
    print("Registering Classes")
    bpy.utils.register_class(QCTBlender)
 
def unregister():
    print("Deregistering Classes")
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
            rank = topologicalObject.find('rank').text
            signature = topologicalObject.find('signature').text
            x = topologicalObject.find('x').text
            y = topologicalObject.find('y').text
            z = topologicalObject.find('z').text
            #convert x,y,z to a position vector - has to be a less verbose way?
            positionVector = mathutils.Vector((float(x),float(y),float(z)))
            cp = CriticalPoint(rank,signature,positionVector)
            cp.printOut() # for debugging - no need to keep the cp reference if not calling this
            cpList.append(cp)

        elif topologicalObject.tag == 'AIL':

            #create a list of Vectors from the file data
            vectorList = []
            for point in topologicalObject.findall('vector'):
                x = point.find('x').text
                y = point.find('y').text
                z = point.find('z').text
                pointVector = mathutils.Vector((float(x),float(y),float(z)))
                vectorList.append(pointVector)

            ail = AtomicInteractionLine(vectorList)
            ailList.append(ail)

        elif topologicalObject.tag == 'IAS':

            vectorList = []
            for point in topologicalObject.findall('vector'):
                x = point.find('x').text
                y = point.find('y').text
                z = point.find('z').text
                pointVector = mathutils.Vector((float(x),float(y),float(z)))
                vectorList.append(pointVector)
 
            ias = Surface(vectorList)
            surfaceList.append(ias)

def createBlenderObjects():
    for cp in cpList:
        #the sphere should be created with the location of the cp object
        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cp.position)

    for surface in surfaceList:
        newMesh = bpy.data.meshes.new('IAS')
        newMesh.from_pydata(surface.points,[],[])
        newMesh.update()
        newObj = bpy.data.objects.new('IAS',newMesh)
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
"name" : "Import QC Topology",
"author" : "Matthew J L Mills <mjohnmills@gmail.com>",
"version" : (0, 0, 0),
"blender" : (2, 69, 0),
"location" : "View 3D > Object Mode > Tool Shelf",
"description" :
"Import a QCT .top File",
"warning" : "",
"wiki_url" : "",
"tracker_url" : "",
"category" : "Add Mesh",
}
