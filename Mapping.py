# Mapping Python 3 Module
# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

# Really there are only 3 objects being drawn - spheres for points, curves for gradient paths
# and meshes for surfaces. The remaining functions ultimately call one of these
# 3 functions. All settings should therefore be arguments to the draw routines.
# would be nice if each returned a dict mapping top objects to 3D objects.

import bpy
import mathutils
from . import Resources

def drawTopology(topology):

    drawCriticalPoints(topology.critical_points)
    #drawGradientVectorField(topology.gradient_vector_field)

def drawGradientVectorField(gradient_vector_field):
    drawMolecularGraph(gradient_vector_field.molecular_graph)
    drawAtomicBasins(gradient_vector_field.atomic_basins)
    drawEnvelopes(gradient_vector_field.envelopes)
    drawAtomicSurfaces(gradient_vector_field.atomic_surfaces)
    drawRingSurfaces(gradient_vector_field.ring_surfaces)
    drawRings(gradient_vector_field.rings)
    drawCages(gradient_vector_field.cages)

def drawCriticalPoints(critical_points):

    elementRadii = Resources.defineRadii()
    for cp in critical_points:
        cpLocation = mathutils.Vector(cp.position_vector)
        cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(location=cpLocation,size=0.1*elementRadii[cp.computeType()],segments=32,ring_count=16)
        # now attach an appropriate material to the sphere

def drawMolecularGraph(molecular_graph):

    bpy.ops.curve.primitive_bezier_circle_add()
    bpy.context.scene.objects.active = bpy.data.objects['BezierCircle']
    bpy.context.object.name = 'AIL-BevelCircle'
    bpy.ops.transform.resize(value=(0.25,0.25,0.25))

    for ail in molecular_graph:
        drawAtomicInteractionLine(ail,material,bpy.data.objects['AIL-BevelCircle'])

def drawAtomicInteractionLine(atomic_interaction_line,bevel):
    for gradient_path in atomic_interaction_line.gradient_paths:
        drawGradientPath(gradient_path,material,bevel)

def drawAtomicBasins(atomic_basins):
    for atomic_basin in atomic_basins:
        for gradient_path in atomic_basin.gradient_paths:
            drawGradientPath(gradient_path,material,bevel)

def drawEnvelopes(envelopes):
    for envelope in envelopes:
        if (not envelope.triangulation):
            #draw point cloud
            print("fix me")
        else:
            drawMesh(triangulation)

def drawAtomicSurfaces(atomic_surfaces):
    for atomic_surface in atomic_surfaces:
        for interatomic_surface in atomic_surface.interatomic_surfaces:
            if (not interatomic_surface.triangulation):
                # draw points
                print("fix me")
            else:
                drawMesh(triangulation)

def drawRingSurfaces(ring_surfaces):
    for ring_surface in ring_surfaces:
        for gradient_path in ring_surface.gradient_paths:
            drawGradientPath(gradient_path)

def drawRing(ring):
    for atomic_interaction_line in ring.atomic_interaction_lines:
        drawAtomicInteractionLine(atomic_interaction_line)

def drawCage(cage):
    for ring in cage.rings:
        drawRing(ring)

def drawMesh(triangulation,material):

    newMesh = bpy.data.meshes.new('SURFACE')
    if (not triangulation.faces):
        newMesh.from_pydata(triangulation.points,triangulation.edges,[])
    else:
        newMesh.from_pydata(triangulation.points,[],triangulation.faces)

    newMesh.update()
    newObj = bpy.data.objects.new('SURFACE',newMesh)
    newObj.data.materials.append(material)
    bpy.context.scene.objects.link(newObj)

def drawGradientPath(gradient_path,material,bevel):

    weight = 1
    cList = gradient_path.points
    curveData = bpy.data.curves.new(type='CURVE')
    curveData.dimesions - '3D'

    objectData = bpy.data.objects.new('ObjCurve',curveData)
    objectData.location = (0,0,0)
    objectData.data.materials.append(material)
    objectData.data.bevel_object = bevel
    bpy.context.scene.objects.link(objectData)

    polyLine = curveData.splines.new('POLY')
    polyLine.points.add(len(cList)-1)
    for num in range(len(cList)):
        x,y,z = cList[num].position_vector
        polyLine.points[num].co = (x,y,z,weight)


# need a dict that assigns materials based on element
