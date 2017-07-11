# ParseTopology Python 3 Module
# Dr. Matthew J L Mills - Rhorix 1.0

# Rhorix uses the ElementTree API, a simple and lightweight XML parser included in Python 3.
# Please be aware of XML vulnerabilities! https://docs.python.org/3/library/xml.html#xml-vulnerabilities
import xml.etree.ElementTree as ET
from . import TopologyClasses

# For debugging purposes you may want to write a Python topology object to stdout
def printTopology(topology):

    print (topology.name)
    for nucleus in topology.nuclei:
        print (nucleus.element,nucleus.position_vector)
    for cp in topology.critical_points:
        print (cp.rank,cp.signature,cp.position_vector,cp.scalar_properties)
    printGradientVectorField(topology.gradient_vector_field)

def printGradientVectorField(gvf):
    
    for ail in gvf.molecular_graph.atomic_interaction_lines:
        print(ail)

# The following functions are all required for complete parsing of a Topology file

# Function reads XML file matching Topology.dtd and returns Topology object
def parseTopology(filepath):

    # Call the parse method of ElementTree to read filepath from disk
    topologyTree = ET.parse(filepath) # ElementTree object - whole document as a single tree
    # Validate the topologyTree using the Topology.dtd document model
    # Get a reference to the root element
    topologyRoot = topologyTree.getroot() # Element object (has tag and dict 'attrib') - single node of tree

    name = topologyRoot.find('SystemName').text
    # As some CPs carry references to nuclei, read these first
    nuclei = []
    for nucleus in topologyRoot.find('Nuclei').iter('Nucleus'):
         nuclei.insert(parseNucleusIndex(nucleus),parseNucleus(nucleus))

    # CPs are referred to by GVF objects, read those next
    critical_points = []
    for cp in topologyRoot.findall('CriticalPoint'):
         critical_points.insert(parseCriticalPointIndex(cp),parseCriticalPoint(cp))

    gradient_vector_field = parseGradientVectorField(topologyRoot.find('GradientVectorField'))

    return TopologyClasses.Topology(name,nuclei,critical_points,gradient_vector_field)

def parseGradientVectorField(GradientVectorFieldElement):
    molecular_graph = parseMolecularGraph(GradientVectorFieldElement.find('MolecularGraph'))

    atomic_basins = []
    for atomic_basin in GradientVectorFieldElement.findall('AtomicBasin'):
        atomic_basins.append(parseAtomicBasin(atomic_basin))

    envelopes = []
    for envelope in GradientVectorFieldElement.findall('Envelope'):
        envelopes.append(parseEnvelope(envelope))

    atomic_surfaces = []
    for atomic_surface in GradientVectorFieldElement.findall('AtomicSurface'):
        atomic_surfaces.append(parseAtomicSurface(atomic_surface))

    ring_surfaces = []
    for ring_surface in GradientVectorFieldElement.findall('RingSurface'):
        ring_surfaces.append(parseRingSurface(ring_surface))

    rings = []
    for ring in GradientVectorFieldElement.findall('Ring'):
        rings.append(parseRing(ring))

    cages = []
    for cage in GradientVectorFieldElement.findall('Cage'):
        cages.append(parseCage(cage))

    return TopologyClasses.GradientVectorField(molecular_graph,atomic_basins,envelopes,atomic_surfaces,ring_surfaces,rings,cages)

def parseRing(RingElement):
    atomic_interaction_lines = []
    for atomic_interaction_line in RingElement.findall('AtomicInteractionLine'):
        atomic_interaction_lines.append(parseAtomicInteractionLine(atomic_interaction_line))
    return TopologyClasses.Ring(atomic_interaction_lines)

def parseCage(CageElement):
    rings = []
    for ring in CageElement.findall('Ring'):
        rings.append(parseRing(ring))
    return TopologyClasses.Cage(rings)

def parseRingSurface(RingSurfaceElement):
    gradient_paths = []
    for gradient_path in RingSurfaceElement.findall('GradientPath'):
        gradient_paths.append(parseGradientPath(gradient_path))
    return TopologyClasses.RingSurface(gradient_paths)

def parseAtomicSurface(AtomicSurfaceElement):
    interatomic_surfaces = []
    for interatomic_surface in AtomicSurfaceElement.findall('InteratomicSurface'):
        interatomic_surfaces.append(parseInteratomicSurface(interatomic_surface))
    return TopologyClasses.AtomicSurface(interatomic_surfaces)

def parseInteratomicSurfaces(InteratomicSurfaceElement):
    gradient_paths = []
    for gradient_path in InteratomicSurfaceElement.findall('GradientPath'):
        gradient_paths.append(parseGradientPath(gradient_path))
    triangulation= parseTriangulation(InteratomicSurfaceElement.find('Triangulation'))
    return TopologyClasses.InteratomicSurface(gradient_paths,triangulation)

def parseAtomicBasin(AtomicBasinElement):
    gradient_paths = []
    for gradient_path in AtomicBasinElement.findall('GradientPath'):
        gradient_paths.append(parseGradientPath(gradient_path))
    return TopologyClasses.AtomicBasin(gradient_paths)

def parseEnvelope(EnvelopeElement):
    isovalue = float(EnvelopeElement.find('isovalue').text)
    points = []
    for point in EnvelopeElement.findall('Point'):
        points.append(parsePoint(point))
    triangulation = parseTriangulation(EnvelopeElement.find('Triangulation'))
    return TopologyClasses.Envelope(isovalue,points,triangulation)

def parseTriangulation(TriangulationElement):

    points = []
    for point in TriangulationElement.findall('Point'):
        points.append(parsePoint(point))

    edges = []
    for edge in TriangulationElement.findall('Edge'):
        edges.append(parseEdge(edge))

    faces = []
    for face in TriangulationElement.findall('Face'):
        faces.append(parseFace(face))

    return TopologyClasses.Triangulation(points,edges,faces)

def parseEdge(EdgeElement):
    a = int(EdgeElement.find('edge_a').text)
    b = int(EdgeElement.find('edge_b').text)
    return TopologyClasses.Edge(a,b)

def parseFace(FaceElement):
    a = int(FaceElement.find('face_a').text)
    b = int(FaceElement.find('face_b').text)
    c = int(FaceElement.find('face_c').text)
    return TopologyClasses.Face(a,b,c)

def parseMolecularGraph(MolecularGraphElement):
    ails = []
    for atomic_interaction_line in MolecularGraphElement.findall('AtomicInteractionLine'):
        ails.append(parseAtomicInteractionLine(atomic_interaction_line))
    return TopologyClasses.MolecularGraph(ails)

def parseAtomicInteractionLine(AtomicInteractionLineElement):
    gradient_paths = []
    for gradient_path in AtomicInteractionLineElement.findall('GradientPath'):
        gradient_paths.append(parseGradientPath(gradient_path))
    return TopologyClasses.AtomicInteractionLine(gradient_paths)

def parseGradientPath(GradientPathElement):
    points = []
    for point in GradientPathElement.findall('Point'):
        points.append(parsePoint(point));
    return TopologyClasses.GradientPath(points)

def parseCriticalPoint(CriticalPointElement):
    rank      = int(CriticalPointElement.find('rank').text)
    signature = int(CriticalPointElement.find('signature').text)
    point = parsePoint(CriticalPointElement.find('Point'))
    return TopologyClasses.CriticalPoint(point.position_vector,point.scalar_properties,rank,signature)

def parseCriticalPointIndex(CriticalPointElement):
    return int(CriticalPointElement.find('cp_index').text)

def parsePoint(PointElement):
    position_vector   = parsePositionVector(PointElement.find('PositionVector'))
    scalar_properties = parseMap(PointElement.find('Map'))
    return TopologyClasses.Point(position_vector,scalar_properties)

def parseMap(MapElement):
    scalar_properties = {}
    for pair in MapElement.findall('Pair'):
        key = pair.find('key').text
        value = float(pair.find('value').text)
        scalar_properties[key] = value
    return scalar_properties

def parseNucleus(NucleusElement):
    element = NucleusElement.find('element').text
    position_vector = parsePositionVector(NucleusElement.find('PositionVector'))
    return TopologyClasses.Nucleus(element,position_vector)

def parseNucleusIndex(NucleusElement):
    return int(NucleusElement.find('nucleus_index').text)

def parsePositionVector(position_vector):
    x = float(position_vector.find('x').text)
    y = float(position_vector.find('y').text)
    z = float(position_vector.find('z').text)
    return (x,y,z)
