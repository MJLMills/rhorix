# Dr. Matthew J L Mills - Rhorix 1.0 - June 2017

# This is a Python implementation of the class hierarchy needed to parse XML files
# adhering to the document model defined in Topology.dtd
# Should be loaded into Rhorix.py as needed

class Topology():
	def __init__(self,nuclei,critical_points,gradient_vector_field):
		this.nuclei = nuclei
        this.critical_points = critical_points
        this.gradient_vector_field = gradient_vector_field

class GradientVectorField():
	def __init__():

class PositionVector():
    
    def __init__(self,x,y,z):
        self.x = x
        self.y = y
        self.z = z

class Point():

    def __init__(self,position_vector,scalar_properties):
        self.position_vector = position_vector
        self.scalar_properties = scalar_properties

class CriticalPoint(Point): # subclass, inherits from Point

    def __init__(self,position_vector,scalar_properties,rank,signature):
    	Point.__init__(self,position_vector,scalar_properties) # call the init of the superclass
    	self.rank = rank
    	self.signature = signature

class GradientPath():
	def __init__(self,points,cp_a,cp_b):
		this.points = points
		this.cp_a = cp_a
		this.cp_b = cp_b

class Envelope():
	def __init__(self,points,nacp):
		this.points = points
		this.nacp = nacp

# the following 2 classes should be concrete implementations of an abstract class 'surface'
class InteratomicSurface():
	def __init__(self,gradient_paths):

class RingSurface():
	def __init__(self,gradient_paths):

class AtomicBasin():
	def __init__(self,gradient_paths):

class AtomicSurface():
	def __init__(self,interatomic_surfaces,envelopes):
		this.interatomic_surfaces = interatomic_surfaces
		this.envelopes = envelopes

class AtomicInteractionLine():
	def __init__(self,gradient_paths):

class MolecularGraph():
	def __init__(self,atomic_interaction_lines):

class Ring():
	def __init__(self,atomic_interaction_lines):

class Cage():
	def __init__(self,rings):

class Triangulation(): # a surface is either composed of GPs or a triangulation of points
    def __init__(self,points,edges,faces)






