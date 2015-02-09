import xml.etree.ElementTree as ET
import bpy

cpList = [] #collection of CPs

class CriticalPoint():

    def __init__(self, rank, signature, position): #this is called on instantiation of the class
        self.rank = rank
        self.signature = signature
        self.position = position

    def printOut(self): # just for debugging
        print('RANK:      ' + self.rank)
        print('SIGNATURE: ' + self.signature)
        print('POSITION:  ' + self.position[0] + ' ' + self.position[1] + ' ' + self.position[2])
#*#*#*
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


     def createBlenderObjects():
         for cp in cpList:
             position = (0,0,0)
             cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=position)


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
  
def register():
    print("Registering Classes")
    bpy.utils.register_class(QCTBlender) # add the defined Operator to the built-in collection
 
def unregister():
    print("Deregistering Classes")
    bpy.utils.register_class(QCTBlender) # add the defined Operator to the built-in collection

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
            positionVector = []
            positionVector.append(x)
            positionVector.append(y)
            positionVector.append(z)
            cp = CriticalPoint(rank,signature,positionVector)
            cp.printOut() # for debugging - no need to keep the cp reference if not calling this
            cpList.append(cp)

    def createBlenderObjects():
        for cp in cpList:
            position = (0,0,0)
            cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=position)


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

bl_info = \
{
"name" : "Import QC Topology",
"author" : "Matthew M L Mills <mjohnmills@gmail.com>",
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
