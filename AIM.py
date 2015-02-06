import xml.etree.ElementTree as ET

class CriticalPoint():

    def __init__(self, rank, signature, position): #this is called on instantiation of the class
    #need to add rank, signature, position and have them accessible

class AtomicInteractionLine():

    def __init__(self)
    #add vector of points on the line

class InteratomicSurface

    def __init__(self)
    #add vector of points on the surface and connectivity, associated NACP

class headClass():

    def readTopology(self,filename):
    #given an open topology file create all the corresponding python objects
    topologyTree = ET.parse(filename)
    topologyRoot = topologyTree.getRoot()
    if (topologyRoot.tag /= 'topology') #fail attempt

    for topologicalObject in topologyRoot:
        if (topologicalObject.tag = 'CP'):
            #add a CP to the scene with the appropriate data
            rank = topologicalObject.find(rank)
            signature = topologicalObject.find(signature)
            x = topologicalObject.find(x)
            y = topologicalObject.find(y)
            z = topologicalObject.find(z)
            #convert x,y,z to a position vector

    def createScene():
    #turn the in-memory topology objects into 3D blender objects and make them appear on screen

#define further operators that select based on given properties (i.e. all BCPs, all oxygen surfaces, etc.)
