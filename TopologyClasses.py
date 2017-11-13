# TopologyClasses Python 3 Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

# This is a Python implementation of the class hierarchy needed to parse XML files
# adhering to the document model defined in Topology.dtd.

import mathutils
import math

class Point():
    def __init__(self,position_vector,scalar_properties):
        self.position_vector   = position_vector
        self.scalar_properties = scalar_properties

class Topology():
	
    def __init__(self,name,nuclei,critical_points,gradient_vector_field):
        self.name                  = name
        self.nuclei                = nuclei
        self.critical_points       = critical_points
        self.gradient_vector_field = gradient_vector_field

    # Find the center of the distribution of critical points
    def computeCenter(self):

        x_total = 0.0
        y_total = 0.0
        z_total = 0.0

        for cp in self.critical_points:
            x_total += cp.position_vector[0]
            y_total += cp.position_vector[1]
            z_total += cp.position_vector[2]

        N = len(self.critical_points)
        x_origin = x_total / N
        y_origin = y_total / N
        z_origin = z_total / N

        #return mathutils.Vector((float(x_origin),float(y_origin),float(z_origin)))
        return (x_origin,y_origin,z_origin)

    # Get the radius of a sphere containing all the critical point objects
    def computeRadius(self,center):

        max = float('-inf')

        position = [0.0, 0.0, 0.0]
        for cp in self.critical_points:
            position[0] = cp.position_vector[0] - center[0]
            position[1] = cp.position_vector[1] - center[1]
            position[2] = cp.position_vector[2] - center[2]
            r = math.sqrt(position[0]*position[0] + position[1]*position[1] + position[2]*position[2])

            if position[0] > max:
                max = position[0]

        return max

class Nucleus():
    def __init__(self,element,position_vector):
        self.element         = element
        self.position_vector = position_vector

class CriticalPoint(Point):
    def __init__(self,position_vector,scalar_properties,rank,signature):
        Point.__init__(self,position_vector,scalar_properties)
        self.rank          = rank
        self.signature     = signature

    def computeType(self):
        if self.rank == 3:
            if self.signature == -3:
                return "nacp" # element of nucleus
            elif self.signature == 3:
                return "ccp"
            elif self.signature == 1:
                return "rcp"
            elif self.signature == -1:
                return "bcp"
            else:
                return "unk" # should not be possible
        else:
            return "dgn"

    def toStdout(self):
        print("CriticalPoint")
        print('rank = ', self.rank)
        print('signature = ', self.signature)

class GradientVectorField():
    def __init__(self,molecular_graph,atomic_basins,envelopes,atomic_surfaces,ring_surfaces,rings,cages):
        self.molecular_graph = molecular_graph
        self.atomic_basins   = atomic_basins
        self.envelopes       = envelopes
        self.atomic_surfaces = atomic_surfaces
        self.ring_surfaces   = ring_surfaces
        self.rings           = rings
        self.cages           = cages

class MolecularGraph():
    def __init__(self,atomic_interaction_lines):
        self.atomic_interaction_lines = atomic_interaction_lines

class AtomicBasin():
    def __init__(self,gradient_paths):
        self.gradient_paths = gradient_paths

    def getNuclearAttractorCriticalPointIndex(self,critical_points):
        for gradient_path in self.gradient_paths:
            for index in gradient_path.cp_indices:
                if (critical_points[index].computeType() == 'nacp'):
                    return index

# An envelope is a set of points with an optional triangulation thereof.
# As it does not have gradient paths it must have an explicit critical point member.
class Envelope():
    def __init__(self,isovalue,points,triangulation):
        self.isovalue      = isovalue
        self.points        = points
        self.triangulation = triangulation

# An atomic surface is a set of interatomic surfaces sharing a common BCP
class AtomicSurface():
    def __init__(self,interatomic_surfaces,nacp_index=0):
        self.interatomic_surfaces = interatomic_surfaces
        self.nacp_index = nacp_index

# A ring surface is a set of gradient paths sharing a single RCP
# There are a set of ring paths - GPs from the RCP to BCPs
# and the remainder connect the RCP to nuclei connected by the BCPs
class RingSurface():
    def __init__(self,gradient_paths):
        self.gradient_paths = gradient_paths

    def getRingCriticalPoint():
        for gradient_path in gradient_paths:
            for cp in gradient_path.cp_indices:
                if (cp.rank == 3 and cp.signature == +1):
                    return cp

class AtomicInteractionLine():
    def __init__(self,gradient_paths):
        self.gradient_paths = gradient_paths

    def getBCP(self,critical_points):
        for gradient_path in self.gradient_paths:
            for index in gradient_path.cp_indices:
                if (critical_points[index].computeType() == 'bcp'):
                    return critical_points[index]

    def getNuclearIndices(self,critical_points):
        indices = []
        for gradient_path in self.gradient_paths:
            for index in gradient_path.cp_indices:
                if (critical_points[index].computeType() == 'nacp'):
                    indices.append(index)
        return indices

# The gradient paths of an interatomic surface share a single BCP
class InteratomicSurface():
    def __init__(self,gradient_paths,triangulation):
        self.gradient_paths = gradient_paths
        self.triangulation  = triangulation

    def getBondCriticalPoint():
        for gradient_path in gradient_paths:
            for cp in gradient_path.critical_points:
                if (cp.rank == 3 and cp.signature == -1):
                    return cp

class Triangulation():
    def __init__(self,points,edge_objects,face_objects):
        self.points = points
        self.edge_objects  = edge_objects
        self.face_objects  = face_objects
        self.edge_arrays = []
        self.face_arrays = []
        for edge in edge_objects:
            edge_array = [edge.a,edge.b]
            self.edge_arrays.append(edge_array)
        for face in face_objects:
            face_array = [face.a,face.b,face.c]
            self.face_arrays.append(face_array)

class Edge():
    def __init__(self,a,b):
        self.a = a
        self.b = b

class Face():
    def __init__(self,a,b,c):
        self.a = a
        self.b = b
        self.c = c

class GradientPath():
    def __init__(self,cp_indices,points):
        self.cp_indices = cp_indices
        self.points = points

    def getNuclearIndex(self,critical_points):
        for index in self.cp_indices:
            if (critical_points[index].computeType() == 'nacp'):
                return index

# A ring is the set of AILs bounding a RCP
class Ring():
    def __init__(self,atomic_interaction_lines):
        self.atomic_interaction_lines = atomic_interaction_lines

# A cage is the set of rings bounding a CCP
class Cage():
    def __init__(self,rings):
        self.rings = rings
		
