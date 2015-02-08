import xml.etree.ElementTree as ET

cpList = [] #collection of all CPs

class CriticalPoint():

    def __init__(self, rank, signature, position): #this is called on instantiation of the class
        self.rank = rank
        self.signature = signature
        self.position = position

    def printOut(self):
        print('RANK:      ' + self.rank)
        print('SIGNATURE: ' + self.signature)
        print('POSITION:  ' + self.position[0] + self.position[1] + self.position[2])

def readTopology(filepath):
    #given an open topology file create all the corresponding python objects
    topologyTree = ET.parse(filepath)
    topologyRoot = topologyTree.getroot()
    if topologyRoot.tag != 'topology':
        print('Not a Topology File')
        exit(1)

    for topologicalObject in topologyRoot:

        if topologicalObject.tag == 'CP':
            #add a CP to the scene with the appropriate data
            rank = topologicalObject.find('rank').text
            signature = topologicalObject.find('signature').text
            x = topologicalObject.find('x').text
            y = topologicalObject.find('y').text
            z = topologicalObject.find('z').text
            #convert x,y,z to a position vector
            positionVector = []
            positionVector.append(x)
            positionVector.append(y)
            positionVector.append(z)
            cp = CriticalPoint(rank,signature,positionVector)
            cp.printOut()
            cpList.append(cp)

class main():

    readTopology('example.top')
