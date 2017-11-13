# Mapping Python 3 Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

# These functions perform the mapping between topological objects and their 3D counterparts.
# There are ultimately only 3 objects being drawn - spheres for points, curves for gradient paths
# and meshes for surfaces. The remaining functions eventually call one or more of the
# 3 functions that create these objects.

import bpy
import mathutils
import time
from . import Resources, Materials, TopologyClasses

def drawTopology(topology,
                 drawNACP=True,
                 color_bonds=True,
                 color_nonbonds=False,
                 nucleus_segments=32,
                 nucleus_ring_count=16,
                 nucleus_subsurf_render_levels=4,
                 cp_segments=32,
                 cp_ring_count=16,
                 cp_subsurf_render_levels=4,
                 triangulate_basins=True,
                 triangulate_surfaces=True,
                 max_rho=0.0):

    elementRadii     = Resources.defineRadii()
    cpMaterials      = Materials.createAllMaterials('critical_point','SURFACE')
    surfaceMaterials = Materials.createAllMaterials('interatomic_surface','WIRE')
    basinMaterials   = Materials.createAllMaterials('atomic_basin','WIRE')
    Materials.createGenericMaterials()

    start = time.time()
    drawNuclei(topology.nuclei,
               elementRadii,
               nucleus_segments=nucleus_segments,
               nucleus_ring_count=nucleus_ring_count,
               nucleus_subsurf_render_levels=nucleus_subsurf_render_levels)

    print('Nuclei Time ', time.time() - start)

    start = time.time()
    drawCriticalPoints(topology.critical_points,
                       elementRadii,
                       drawNACP=drawNACP,
                       cp_segments=cp_segments,
                       cp_ring_count=cp_ring_count,
                       cp_subsurf_render_levels=cp_subsurf_render_levels)

    print('CP Time ', time.time() - start)

    start = time.time()
    drawGradientVectorField(topology.gradient_vector_field,
                            topology.critical_points,
                            topology.nuclei,
                            color_bonds=color_bonds,
                            color_nonbonds=color_nonbonds,
                            triangulate_basins=triangulate_basins,
                            triangulate_surfaces=triangulate_surfaces,
                            max_rho=max_rho)

    print('GVF Time ', time.time() - start)

def drawGradientVectorField(gradient_vector_field,
                            critical_points,
                            nuclei,
                            color_bonds=True,
                            color_nonbonds=False,
                            triangulate_basins=False,
                            triangulate_surfaces=False,
                            max_rho=0.0):

    drawMolecularGraph(gradient_vector_field.molecular_graph,
                       critical_points,
                       nuclei,
                       color_bonds=color_bonds,
                       color_nonbonds=color_nonbonds,
                       weak_limit=0.025)

    drawAtomicBasins(gradient_vector_field.atomic_basins,
                     critical_points,
                     nuclei,
                     triangulate=triangulate_basins)
    
    drawEnvelopes(gradient_vector_field.envelopes)
    
    drawAtomicSurfaces(gradient_vector_field.atomic_surfaces,
                       critical_points,
                       nuclei,
                       triangulate=triangulate_surfaces,
                       max_rho=max_rho)
    
    drawRingSurfaces(gradient_vector_field.ring_surfaces)
    
    drawRings(gradient_vector_field.rings) # note: no implementation
    
    drawCages(gradient_vector_field.cages) # note: no implementation

def drawCriticalPoints(critical_points,
                       radii,
                       drawNACP=True,
                       cp_segments=32,
                       cp_ring_count=16,
                       cp_subsurf_render_levels=4):

    critical_point_radius_coeff = 0.25

    for cp in critical_points:

        kind = cp.computeType()
        if (kind != 'nacp' or drawNACP == True):
            location = mathutils.Vector(cp.position_vector)
            radius = critical_point_radius_coeff * radii[kind]
            material_name = kind+'-critical_point-material'
            drawSphere(kind,location,radius,material_name,segments=cp_segments,ring_count=cp_ring_count,subsurf_render_levels=cp_subsurf_render_levels)

def drawNuclei(nuclei,
               radii,
               nucleus_segments=32,
               nucleus_ring_count=16,
               nucleus_subsurf_render_levels=4):

    nuclear_radius_coeff = 0.25

    for nucleus in nuclei:

        element = nucleus.element.lower()
        location = mathutils.Vector(nucleus.position_vector)
        radius = nuclear_radius_coeff * radii[element]
        material_name = element+'-critical_point-material'
        drawSphere(element,location,radius,material_name,segments=nucleus_segments,ring_count=nucleus_ring_count,subsurf_render_levels=nucleus_subsurf_render_levels)

def drawSphere(name,
               location,
               size,
               material_name,
               segments=32,
               ring_count=16,
               subsurf_render_levels=4):

    """ Draw a sphere """

    cpSphere = bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=ring_count,size=size,location=location)
    bpy.context.object.name = name

    bpy.context.scene.objects.active = bpy.context.object
    bpy.context.object.data.materials.append(bpy.data.materials[material_name])

    #Create and apply the subsurface modifiers for smooth rendering
    if (subsurf_render_levels > 1):
        bpy.context.object.modifiers.new("subd", type='SUBSURF')
        bpy.context.object.modifiers['subd'].levels=1
        bpy.context.object.modifiers['subd'].render_levels=subsurf_render_levels
        bpy.ops.object.modifier_apply(apply_as='DATA', modifier='subd')

def drawMolecularGraph(molecular_graph,
                       critical_points,
                       nuclei,
                       color_bonds=True,
                       color_nonbonds=True,
                       weak_limit=0.025):

    bond_scale    = 0.200
    nonbond_scale = 0.050

    createBevelCircle('non_bond-BevelCircle',nonbond_scale)
    createBevelCircle('bond-BevelCircle',bond_scale)

    for ail in molecular_graph.atomic_interaction_lines:
        bcp = ail.getBCP(critical_points)

        is_weak = False
        if 'rho' in bcp.scalar_properties:
            if bcp.scalar_properties.get('rho') < weak_limit:
                is_weak = True

        if (is_weak == True):
            if (color_nonbonds == True):
                for gradient_path in ail.gradient_paths:
                    nacp_index = gradient_path.getNuclearIndex(critical_points)
                    element = nuclei[nacp_index].element.lower()
                    material_name = element+'-critical_point-material'
                    drawGradientPath(gradient_path,bpy.data.objects['bond-BevelCircle'],material_name)
            else:
                drawAtomicInteractionLine(ail,bpy.data.objects['non_bond-BevelCircle'],'Non-Bond-curve-material')
        else:
            if (color_bonds == True):
                for gradient_path in ail.gradient_paths:
                    nacp_index = gradient_path.getNuclearIndex(critical_points)
                    element = nuclei[nacp_index].element.lower()
                    material_name = element+'-critical_point-material'
                    drawGradientPath(gradient_path,bpy.data.objects['bond-BevelCircle'],material_name)
            else:
                drawAtomicInteractionLine(ail,bpy.data.objects['bond-BevelCircle'],'Bond-curve-material')

def drawAtomicInteractionLine(atomic_interaction_line,bevel,material_name):

    for gradient_path in atomic_interaction_line.gradient_paths:
        drawGradientPath(gradient_path,bevel,material_name) 

def drawAtomicBasins(atomic_basins,critical_points,nuclei,triangulate=False):

    basin_path_scale = 0.01

    bevel_name = 'Basin-BevelCircle'
    createBevelCircle(bevel_name,basin_path_scale)

    for atomic_basin in atomic_basins:
        nacp_index = atomic_basin.getNuclearAttractorCriticalPointIndex(critical_points)
        element = nuclei[nacp_index].element.lower()
        material_name = element+'-atomic_basin-material'

        if (triangulate == True):

            surface_edges  = []
            surface_faces  = []
            surface_points = []

            index = 0
            for gradient_path in atomic_basin.gradient_paths:
                for i, point in enumerate(gradient_path.points):
                    surface_points.append(point)
                    if (i < len(gradient_path.points)-1): # ignore last point
                        surface_edges.append(TopologyClasses.Edge(index,index+1))
                    index += 1

            surface_triangulation = TopologyClasses.Triangulation(surface_points,surface_edges,surface_faces)
            drawMesh(surface_triangulation,material_name)

        else:
            for gradient_path in atomic_basin.gradient_paths:
                drawGradientPath(gradient_path,bpy.data.objects[bevel_name],material_name)

def drawEnvelopes(envelopes):
    for envelope in envelopes:
        if (not envelope.triangulation):
            print("drawEnvelopes: Auto-triangulation be implemented")
        else:
            drawMesh(envelope.triangulation,'Bond-curve-material')

def drawAtomicSurfaces(atomic_surfaces,critical_points,nuclei,triangulate=False,max_rho=0.0000):

    ias_path_scale = 0.005

    bevel_name = 'IAS-BevelCircle'
    createBevelCircle(bevel_name,ias_path_scale)

    for atomic_surface in atomic_surfaces:
        for interatomic_surface in atomic_surface.interatomic_surfaces:
            if (interatomic_surface.triangulation is None):

                if (triangulate == True):

                    surface_edges  = []
                    surface_faces  = []
                    surface_points = []

                    material_name = 'Bond-curve-material'

                    for gradient_path in interatomic_surface.gradient_paths:
                        nacp_index = gradient_path.getNuclearIndex(critical_points)
                        element = nuclei[nacp_index].element.lower()
                        material_name = element+'-interatomic_surface-material'
                        for point in gradient_path.points:
                            if (point.scalar_properties.get('rho') > max_rho):
                                surface_points.append(point)

                    index = 0
                    num_paths = len(interatomic_surface.gradient_paths)
                    for j, gradient_path in enumerate(interatomic_surface.gradient_paths):

                        num_points_on_path = len(gradient_path.points)

                        if (j < num_paths-1):
                            n_points_on_next_path = len(interatomic_surface.gradient_paths[j+1].points)
                            surface_edges.append(TopologyClasses.Edge(index+num_points_on_path-1,index+num_points_on_path+n_points_on_next_path-1))
                        else:
                            n_points_on_next_path = len(interatomic_surface.gradient_paths[0].points)
                            surface_edges.append(TopologyClasses.Edge(index+num_points_on_path-1,n_points_on_next_path-1))

                        # walk along the path point by point
                        for i, point in enumerate(gradient_path.points): # [:-1]

                            # make all connections along each gradient path
                            if (i < num_points_on_path-1): # ignore last point
                                surface_edges.append(TopologyClasses.Edge(index,index+1))

                            # make connections between neighbouring gradient paths
                            if (i > 0 and j < num_paths-1):
                                if (i < n_points_on_next_path-1):
                                    surface_edges.append(TopologyClasses.Edge(index,index+num_points_on_path))                             
                                
                            elif (i > 0 and j == num_paths-1):
                                if (i < num_points_on_path-1):
                                    surface_edges.append(TopologyClasses.Edge(index,i))

                            index += 1

                    surface_triangulation = TopologyClasses.Triangulation(surface_points,surface_edges,surface_faces)
                    drawMesh(surface_triangulation,material_name)

                else:

                    for gradient_path in interatomic_surface.gradient_paths:
                        nacp_index = gradient_path.getNuclearIndex(critical_points)
                        element = nuclei[nacp_index].element.lower()
                        material_name = element+'-interatomic_surface-material'
                        drawGradientPath(gradient_path,bpy.data.objects['IAS-BevelCircle'],material_name)

            else:
                element = nuclei[nacp_index].element.lower()
                material_name = element+'-interatomic_surface-material'
                drawMesh(interatomic_surface.triangulation,material_name)

def drawRingSurfaces(ring_surfaces,material_name='Ring-Path-curve-material'):

    ring_path_scale = 0.1

    createBevelCircle('RingSurfaces-BevelCircle',ring_path_scale)

    for ring_surface in ring_surfaces:
        for gradient_path in ring_surface.gradient_paths:
            drawGradientPath(gradient_path,bpy.data.objects['RingSurfaces-BevelCircle'],material_name)

def drawMesh(triangulation,material_name):

    newMesh = bpy.data.meshes.new('SURFACE')
    coords = []
    for point in triangulation.points:
        vec = mathutils.Vector(point.position_vector)
        coords.append(vec)

    if (not triangulation.face_objects):
        newMesh.from_pydata(coords,triangulation.edge_arrays,[])
    else:
        newMesh.from_pydata(coords,[],triangulation.face_arrays)

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

def createBevelCircle(name,scale):

    bpy.ops.curve.primitive_bezier_circle_add()
    bpy.context.scene.objects.active = bpy.data.objects['BezierCircle']
    bpy.context.object.name = name
    bpy.context.object.hide_render = True
    bpy.ops.transform.resize(value=(scale,scale,scale))

def drawRings(rings):
    print("drawRings: To be implemented")

def drawRing(ring):
    for atomic_interaction_line in ring.atomic_interaction_lines:
        drawAtomicInteractionLine(atomic_interaction_line)

def drawCages(cages):
    print("drawCages: To be implemented")

def drawCage(cage):
    for ring in cage.rings:
        drawRing(ring)

