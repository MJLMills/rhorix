# Mapping Python 3 Module
# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

# Really there are only 3 objects being drawn - spheres for points, curves for gradient paths
# and meshes for surfaces. The remaining functions ultimately call one of these
# 3 functions. All settings should therefore be arguments to the draw routines.

import bpy
import mathutils
import time
from . import Resources, Materials

def drawTopology(topology):

    elementRadii = Resources.defineRadii()
    cpMaterials = Materials.createAllMaterials('critical_point')
    surfaceMaterials = Materials.createAllMaterials('interatomic_surface')
    Materials.createGenericMaterials()

    start = time.time()
    drawNuclei(topology.nuclei,elementRadii)
    print('Nuclei Time ', time.time() - start)

    start = time.time()
    drawCriticalPoints(topology.critical_points,elementRadii,0)
    print('CP Time ', time.time() - start)

    start = time.time()
    drawGradientVectorField(topology.gradient_vector_field,topology.critical_points,topology.nuclei)
    print('GVF Time ', time.time() - start)

def drawGradientVectorField(gradient_vector_field,critical_points,nuclei):

    drawMolecularGraph(gradient_vector_field.molecular_graph,critical_points)
    drawAtomicBasins(gradient_vector_field.atomic_basins,critical_points,nuclei)
    drawEnvelopes(gradient_vector_field.envelopes)
    drawAtomicSurfaces(gradient_vector_field.atomic_surfaces)
    drawRingSurfaces(gradient_vector_field.ring_surfaces)
    drawRings(gradient_vector_field.rings)
    drawCages(gradient_vector_field.cages)

def drawCriticalPoints(critical_points,radii,drawNACP=0):

    critical_point_radius_coeff = 0.25

    for cp in critical_points:

        kind = cp.computeType()
        if (kind != 'nacp' or drawNACP == 1):
            location = mathutils.Vector(cp.position_vector)
            radius = critical_point_radius_coeff * radii[kind]
            material_name = kind+'-critical_point-material'
            drawSphere(kind,location,radius,material_name)

def drawNuclei(nuclei,radii):

    nuclear_radius_coeff = 0.25
    for nucleus in nuclei:

        element = nucleus.element.lower()
        location = mathutils.Vector(nucleus.position_vector)
        radius = nuclear_radius_coeff * radii[element]
        material_name = element+'-critical_point-material'
        drawSphere(element,location,radius,material_name)

def drawSphere(name,location,size,material_name):
    """ Draw a sphere """

    sphere_segments = 32
    sphere_ring_count = 16
    cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(segments=sphere_segments,ring_count=sphere_ring_count,size=size,location=location)
    bpy.context.object.name = name

    #Create and apply the subsurface modifiers for smooth rendering
    subsurf_render_levels = 4
    if (subsurf_render_levels > 1):
        bpy.context.object.modifiers.new("subd", type='SUBSURF')
        bpy.context.object.modifiers['subd'].levels=1
        bpy.context.object.modifiers['subd'].render_levels=subsurf_render_levels
        bpy.context.scene.objects.active = bpy.context.object
        bpy.ops.object.modifier_apply(apply_as='DATA', modifier='subd')
        bpy.context.object.data.materials.append(bpy.data.materials[material_name])

def createBevelCircle(name,scale):

    bpy.ops.curve.primitive_bezier_circle_add()
    bpy.context.scene.objects.active = bpy.data.objects['BezierCircle']
    bpy.context.object.name = name
    bpy.context.object.hide_render = True
    bpy.ops.transform.resize(value=(scale,scale,scale))

def drawMolecularGraph(molecular_graph,critical_points):

    weak_limit = 0.025
    bond_scale = 0.200
    nonbond_scale = 0.05

    createBevelCircle('non_bond-BevelCircle',nonbond_scale)
    createBevelCircle('bond-BevelCircle',bond_scale)

    for ail in molecular_graph.atomic_interaction_lines:
        bcp = ail.getBCP(critical_points)
        if (bcp.scalar_properties.get('rho') < weak_limit):
            drawAtomicInteractionLine(ail,bpy.data.objects['non_bond-BevelCircle'],'Non-Bond-curve-material')
        else:
            drawAtomicInteractionLine(ail,bpy.data.objects['bond-BevelCircle'],'Bond-curve-material')

def drawAtomicInteractionLine(atomic_interaction_line,bevel,material_name):

    for gradient_path in atomic_interaction_line.gradient_paths:
        drawGradientPath(gradient_path,bevel,material_name) 

def drawAtomicBasins(atomic_basins,critical_points,nuclei):

    basin_path_scale = 0.01

    bevel_name = 'Basin-BevelCircle'
    createBevelCircle(bevel_name,basin_path_scale)

    for atomic_basin in atomic_basins:
        nacp_index = atomic_basin.getNuclearAttractorCriticalPointIndex(critical_points)
        element = nuclei[nacp_index].element.lower()
        material_name = element+'-critical_point-material'

        for gradient_path in atomic_basin.gradient_paths:
            drawGradientPath(gradient_path,bpy.data.objects[bevel_name],material_name)

def drawEnvelopes(envelopes):
    for envelope in envelopes:
        if (not envelope.triangulation):
            print("drawEnvelopes: To be implemented")
        else:
            drawMesh(envelope.triangulation,'Bond-curve-material')

def drawAtomicSurfaces(atomic_surfaces):
    for atomic_surface in atomic_surfaces:
        for interatomic_surface in atomic_surface.interatomic_surfaces:
            print(interatomic_surface)
            if (not interatomic_surface.triangulation):
                # draw AILs
                for gradient_path in interatomic_surface.gradient_paths:
                    drawGradientPath(gradient_path,bpy.data.objects['non_bond-BevelCircle'],'Bond-curve-material')
            else:
                drawMesh(triangulation,'Bond-curve-material')

def drawRingSurfaces(ring_surfaces):

    ring_path_scale = 0.1
    createBevelCircle('RingSurfaces-BevelCircle',ring_path_scale)

    for ring_surface in ring_surfaces:
        for gradient_path in ring_surface.gradient_paths:
            drawGradientPath(gradient_path,bpy.data.objects['RingSurfaces-BevelCircle'],'rcp-critical_point-material')

def drawMesh(triangulation,material_name):

    newMesh = bpy.data.meshes.new('SURFACE')
    coords = []
    for point in triangulation.points:
        vec = mathutils.Vector(point.position_vector)
        coords.append(vec)

    if (not triangulation.faces):
        newMesh.from_pydata(coords,triangulation.edges,[])
    else:
        newMesh.from_pydata(coords,[],triangulation.faces)

    newMesh.update()
    newObj = bpy.data.objects.new('SURFACE',newMesh)
    newObj.data.materials.append(bpy.data.materials[material_name])
    bpy.context.scene.objects.link(newObj)

def drawGradientPath(gradient_path,bevel,material_name):

    weight = 1
    cList = gradient_path.points
    curveData = bpy.data.curves.new(name='curve',type='CURVE')
    curveData.dimensions = '3D'

    objectData = bpy.data.objects.new('ObjCurve',curveData)
    objectData.location = (0,0,0)
    objectData.data.materials.append(bpy.data.materials[material_name])
    objectData.data.bevel_object = bevel
    bpy.context.scene.objects.link(objectData)

    polyLine = curveData.splines.new('POLY')
    polyLine.points.add(len(cList)-1)
    for num in range(len(cList)):
        x,y,z = cList[num].position_vector
        polyLine.points[num].co = (x,y,z,weight)

def drawRings(rings):
    print("drawRings: To be implemented")
    #for ring in rings:

def drawRing(ring):
    for atomic_interaction_line in ring.atomic_interaction_lines:
        drawAtomicInteractionLine(atomic_interaction_line)

def drawCages(cages):
    print("drawCages: To be implemented")
    #for cage in cages:

def drawCage(cage):
    for ring in cage.rings:
        drawRing(ring)
