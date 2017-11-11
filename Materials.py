# Materials Python 3 Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

# Materials are usually assigned to points by using the properties of a critical point
# associated with that point. This necessitates the definition of a library of materials
# for different CPs. In addition, the particular material assigned may depend on the nature of
# the point itself - is it a CP, or on a gradient path, or on a triangulated surface? Might want to make
# surface transparent, e.g. while not altering the CP spheres
# For this latter reason, we must create separate sphere, surface dicts
# NACPS  - material assigned according to element of practically coincident nucleus
# NNACPs - all one material
# BCPs   - all one material
# RCPs   - all one material
# CCPS   - all one material
# degen  - all one material
# The goal is to be able to pass a CP to a dict/function and get back the corresponding material

from . import Resources
import bpy

# This function creates a single material for each type of CP in the scene
# and should add them to a dict from each cp to its corresponding material
def createMaterials(critical_points):

    elementColors = Resources.defineColors()
    #create the necessary set of element colors for this topology
    createdList = [] #list of the nuclear types created so far
    for cp in critical_points:
        type = cp.computeType()
        #check the material for this sphere hasn't been made already
        duplicate = False
        for element in createdList:
            if type == element:
                duplicate = True
                break

        #and if it has NOT then make it
        if duplicate == False:
            #create a new material
            createMaterial(elementColors[element],'WIRE',   1.0,element,'critical_point')
            createMaterial(elementColors[element],'WIRE',0.5,element,'surface')
            createdList.append(type)

    # create generic materials for AILs
    createMaterial((0.0,0.0,0.0),'SURFACE',1.0,'AIL','curve')

def createGenericMaterials():
    createMaterial((0.04,0.04,0.04),'SURFACE',1.0,'AIL','curve')
    createMaterial((0.04,0.04,0.04),'SURFACE',1.0,'Bond','curve')
    createMaterial((0.4,0.4,0.4),'SURFACE',1.0,'Non-Bond','curve')
    createMaterial((0.2,0.2,0.2),'SURFACE',1.0,'Ring-Path','curve')

def createAllMaterials(suffix,material_type):

    materials = {}

    # make a copy of the colors dict - colors for each CP type and element
    elementColors = Resources.defineColors()
    # create a material for each CP type and element
    for element in elementColors:
        materials[element] = createMaterial(elementColors[element],material_type,1.0,element,suffix)

    return materials

def createMaterial(color,type,alpha,prefix,suffix):
    mat = bpy.data.materials.new(prefix+'-'+suffix+'-material')
    mat.diffuse_color = color
    mat.diffuse_shader = 'LAMBERT'
    mat.diffuse_intensity = 1.0
    mat.specular_color = (1,1,1)
    mat.specular_shader = 'COOKTORR'
    mat.specular_intensity = 0.5
    mat.alpha = alpha
    mat.ambient = 1
    mat.type = type
