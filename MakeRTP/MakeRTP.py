#!/usr/local/anaconda2/bin/python

import argparse
import numpy as np
import sys


# ---------------------------
#     Parse                
# ---------------------------

parser = argparse.ArgumentParser()

parser.add_argument("-i", dest="inputfile", required=True,
                    help="Input file in PDB format with CONECT entries", metavar="FILE")
parser.add_argument("-o", dest="outputfile", required=True,
                    help="RTP file", metavar="FILE")

args = parser.parse_args()
Input  = args.inputfile
Output = args.outputfile


# ---------------------------
#     Read Data                
# ---------------------------

InputFile  = open(Input)
OutputFile = open(Output,'w')

AtomList   = []
ConectList = []
for Line in InputFile:
    if (Line[0:4] == 'ATOM') or (Line[0:6] == 'HETATM'):
        AtomList.append( [Line.split()[i] for i in [2,3,5,6,7]] )
    if Line[0:6] == 'CONECT':
        ConectList.append( map(int,Line.split()[1:]) )

NAtoms  = len(AtomList)

# --- Check if is a single residue  
for i in range(NAtoms):
    if AtomList[i][1] != AtomList[0][1]:
        sys.exit("Error. There should be only one residue")

# --- Check if if there is at least one CONECT  
if len(ConectList) == 0:
    sys.exit("Error. There must be CONNECT entries")

# --- Check if all atoms are conected  

for i in range(len(AtomList)):
    Conected=False
    for Entry in ConectList:
        for j in range(len(Entry)):
            if i == Entry[j] -1:
                Conected = True
    if Conected == False:
        sys.stdout.write("Warning. Atom "+AtomList[i][0]+" is not conected to other atoms.\n")
        sys.stdout.write("         If this is wrong, add a CONECT entry in "+Input+".\n ")



# ---------------------------
#     Bonds                
# ---------------------------

def distance (a,b):
    a = np.array( a[2:5],dtype=float )
    b = np.array( b[2:5],dtype=float )
    Norm = np.linalg.norm(a-b)/10.
    return "%5.3f"%Norm

BondList = []
for Entry in ConectList:
    for i in range(1,len(Entry)):
        A1 = AtomList[Entry[0] -1]
        A2 = AtomList[Entry[i] -1]
  
        # Eliminates repeated
        Repeated = False
        for Bond in BondList:
            if (A1[0] == Bond[0]) and (A2[0] == Bond[1]):
                    Repeated = True
            if (A1[0] == Bond[1]) and (A2[0] == Bond[0]):
                    Repeated = True
        if not Repeated:
            BondList.append( [ A1[0], A2[0], distance(A1,A2), 627.6 ])
NBonds=len(BondList)




# ---------------------------
#     Angles                
# ---------------------------

def findAtom(AtomName): 
    for Atom in AtomList:
        if Atom[0] == AtomName:
            break
    return Atom

def angle(a,b,c):
    a   = np.array( a[2:5],dtype=float )
    b   = np.array( b[2:5],dtype=float )
    c   = np.array( c[2:5],dtype=float )
    ba  = a-b
    bc  = c-b
    Nba = np.linalg.norm(ba)
    Nbc = np.linalg.norm(bc)
    Angle = np.arccos( ba.dot(bc)/(Nba*Nbc) ) *180 /np.pi
    return  "%5.3f"%Angle


# --- Loop over atoms
# Angles are defined through a the central atom

AngleList = [] 
for Atom in AtomList:

    # --- Creates Bonded List.
    # From all the Bond list keeps the ones bonded with this specific atom

    BondedList=[]
    for Bond in BondList:
        if (Atom[0] == Bond[0]):
            BondedList.append( findAtom(Bond[1]) )
        if (Atom[0] == Bond[1]):
            BondedList.append( findAtom(Bond[0]) )    


    # --- Creates Angle List
    # Iterates over the Bonded list without considering repeated angles 

    for A1 in BondedList:
        for A2 in BondedList:
 
            if A1[0] == A2[0]: 
                continue

            Repeated=False
            for Angle in AngleList:
                if (A1[0] == Angle[0]) and (Atom[0] == Angle[1]) and (A2[0] == Angle[2]):
                        Repeated = True
                if (A1[0] == Angle[2]) and (Atom[0] == Angle[1]) and (A2[0] == Angle[0]):
                        Repeated = True

            if not Repeated:
                AngleList.append([ A1[0], Atom[0], A2[0], angle(A1,Atom,A2), 627.6])

NAngles = len(AngleList)




# ---------------------------
#     Dihedrals                 
# ---------------------------

DihedList = []
for Bond in BondList:

    # --- Creates Bonded List for each atom in bond
    # From all the Bond list keeps the ones bonded with this specific atom

    Atom = findAtom(Bond[0])
    BondedList1=[]
    for xBond in BondList:
        if (Atom[0] == xBond[0]):
            BondedList1.append( findAtom(xBond[1]) )
        if (Atom[0] == xBond[1]):
            BondedList1.append( findAtom(xBond[0]) )

    Atom = findAtom(Bond[1])
    BondedList2=[]
    for xBond in BondList:
        if (Atom[0] == xBond[0]):
            BondedList2.append( findAtom(xBond[1]) )
        if (Atom[0] == xBond[1]):
            BondedList2.append( findAtom(xBond[0]) )

    for A1 in BondedList1:
        for A2 in BondedList2:

            if A1[0] == A2[0]:
                continue
            if A1[0] == Bond[0] or A1[0] == Bond[1]:
                continue
            if A2[0] == Bond[0] or A2[0] == Bond[1]:
                continue

            Repeated=False
            for Dihed in DihedList:
                if (A1[0] == Angle[0]) and (Atom[0] == Angle[1]) and (A2[0] == Angle[2]):
                        Repeated = True
                if (A1[0] == Angle[2]) and (Atom[0] == Angle[1]) and (A2[0] == Angle[0]):
                        Repeated = True

            if not Repeated:
                DihedList.append([ A1[0], Bond[0], Bond[1], A2[0], 0, 0, 0])

NDiheds = len(DihedList)



# ---------------------------
#     OutputFile                
# ---------------------------

OutputFile.write('\n['+AtomList[0][1]+' ]\n')
OutputFile.write('\n [ atoms ]\n')
for i in range(NAtoms):
    OutputFile.write('      '+'%-5s'%AtomList[i][0]+'   XXX   0.0    '+str(i+1)+'\n')

OutputFile.write('\n [ bonds ]\n')
for i in range(NBonds):
    OutputFile.write('      '+'   '.join(map(str,BondList[i][0:4]))+'\n')

OutputFile.write('\n [ angles ]\n')
for i in range(NAngles):
    OutputFile.write('      '+'   '.join(map(str,AngleList[i][0:5]))+'\n')

OutputFile.write('\n [ dihedrals ]\n')
for i in range(NDiheds):
    OutputFile.write('      '+'   '.join(map(str,DihedList[i][0:7]))+'\n')

OutputFile.write('\n [ impropers ]\n')




