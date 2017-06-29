# Materials Python 3 Module
# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

# Materials are usually assigned to points by using the properties of a critical point
# associated with that object. This necessitates the definition of a library of materials
# for different CPs.
# NACPS  - material assigned according to element of practically coincident nucleus
# NNACPs - all one material
# BCPs   - all one material
# RCPs   - all one material
# CCPS   - all one material
# degen  - all one material
# The goal is to be able to pass a CP to a dict/function and get back the corresponding material


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