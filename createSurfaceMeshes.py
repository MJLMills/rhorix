import bpy
import mathutils

class importTopology(bpy.types.Operator):
        bl_idname = "QCT.importTopology"
        bl_label = "Read QCT Surfaces"

    def invoke(self, context, event):
        
    addMesh = bpy.data.meshes.new("ATOM_H1")
    addMesh.from_pydata() #put the data from the file into the mesh
    #each vertex is a mathutils.Vector object. arg 1 to addMesh is an array of vectors, 1 for each vertex
    # then either a list of edges (2-element int arrays) and an empty array []
    # or an empty array and a list of faces (3 or 4 element int arrays)
    addMesh.update() #tell blender the mesh has changed
    addObj = bpy.data.objects.new("ATOM_H1", addMesh) #create a blender datablock for the object
    context.scene.objects.link(addObj) #and link it to the blender scene
    return {"FINISHED"}
    
    #need to read files in
    #create spheres for CPs, meshes for surfaces and cylinders for bonds
