import bpy
import mathutils

class ImportTopology(bpy.types.Operator):
    bl_idname = "qct.import_topology" #operator name
    bl_label = "Import Topology"

    def invoke(self, context, event):
        print("QCT4Blender invoked")
        return {"FINISHED"} #indicates successful completion
#        addMesh = bpy.data.meshes.new("ATOM_H1")
#        addMesh.from_pydata() #put the data from the file into the mesh
        #each vertex is a mathutils.Vector object. arg 1 to addMesh is an array of vectors, 1 for each vertex
        # then either a list of edges (2-element int arrays) and an empty array []
        # or an empty array and a list of faces (3 or 4 element int arrays)
#        addMesh.update() #tell blender the mesh has changed
#        addObj = bpy.data.objects.new("ATOM_H1", addMesh) #create a blender datablock for the object
#        context.scene.objects.link(addObj) #and link it to the blender scene
                
        #need to read files in
        #create spheres for CPs, meshes for surfaces and cylinders for bonds

#put the GUI in the Tool shelf

class ImportTopologyPanel(bpy.types.Panel):
    bl_space_type = "VIEW_3D"
    bl_region_type = "TOOLS"
    bl_context = "objectMode"
    #the above three lines make the panel appear in the toolshelf of the 3D view in object mode
    bl_category = "Create" #determine toolbar tab to place panel in
    bl_label = "Read QC Topology"
        
    def draw(self, context):
        TheCol = self.layout.column(align=True)
        TheCol.operator("qct.import_topology",text="Import Topology")
           
def register():
    print("Registering Classes")
    bpy.utils.register_class(ImportTopology) # add the defined Operator to the built-in collection
    bpy.utils.register_class(ImportTopologyPanel)

def unregister():
    print("Deregistering Classes")
    bpy.utils.register_class(ImportTopology) # add the defined Operator to the built-in collection
    bpy.utils.register_class(ImportTopologyPanel)
    
if __name__ == "main":
    register()

#call register
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
