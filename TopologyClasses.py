# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

#TopologyClasses Module
# This is a Python implementation of the class hierarchy needed to parse XML files
# adhering to the document model defined in Topology.dtd
# Should be loaded into Rhorix.py as needed

class Nucleus():
	def __init__(self,element,position_vector):
		self.element = element
		self.position_vector = position_vector

class Topology():
	def __init__(self,nuclei,critical_points,gradient_vector_field):
		self.nuclei = nuclei
		self.critical_points = critical_points
		self.gradient_vector_field = gradient_vector_field

class GradientVectorField():
	def __init__(self,molecular_graph,atomic_basins,envelopes,atomic_surfaces,ring_surfaces,rings,cages):
		self.molecular_graph = molecular_graph
		self.atomic_basins = atomic_basins
		self.envelopes = envelopes
		self.atomic_surfaces = atomic_surfaces
		self.ring_surfaces = ring_surfaces
		self.rings = rings
		self.cages = cages

class AtomicBasin():
	def __init__(self,gradient_paths):
		self.gradient_paths = gradient_paths

class Envelope():
	def __init__(self,isovalue,points,triangulation):
		self.isovalue = isovalue
		self.points = points
		self.triangulation = triangulation

class AtomicSurface():
	def __init__(self,interatomic_surfaces):
		self.interatomic_surfaces = interatomic_surfaces

class InteratomicSurface():
	def __init__(self,gradient_paths,triangulation):
		self.gradient_paths = gradient_paths
		self.triangulation = triangulation

class RingSurface():
	def __init__(self,gradient_paths):
		self.gradient_paths = gradient_paths

class Triangulation():
	def __init__(self,points,edges,faces):
		self.points = points
		self.edges = edges
		self.faces = faces

class MolecularGraph():
	def __init__(self,atomic_interaction_lines):
		self.atomic_interaction_lines = atomic_interaction_lines

class Ring():
	def __init__(self,atomic_interaction_lines):
		self.atomic_interaction_lines = atomic_interaction_lines

class Cage():
	def __init__(self,rings):
		self.rings = rings

class GradientPath():
	def __init__(self,points):
		self.points = points

class AtomicInteractionLine():
	def __init__(self,gradient_paths):
		self.gradient_paths = gradient_paths

class Point():
	def __init__(self,position_vector,scalar_properties):
		self.position_vector = position_vector
		self.scalar_properties = scalar_properties

class CriticalPoint(Point):
	def __init__(self,position_vector,scalar_properties,rank,signature):
		Point.__init__(self,position_vector,scalar_properties)
		self.rank = rank
		self.signature = signature



