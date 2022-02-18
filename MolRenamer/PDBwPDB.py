#!/usr/local/anaconda2/bin/python

#python rename.py MyQuery.pdb Template.pdb MyFixedQuery.pdb

import sys
import collections
import copy
import argparse


# --------------------------------------
#     Parse                
# --------------------------------------

parser = argparse.ArgumentParser()

parser.add_argument("-q", dest="queryPDB", required=True,
                    help="Query file to be renamed in PDB format with CONECT entries", metavar="PDBfile")
parser.add_argument("-t", dest="templatePDB", required=True,
                    help="Template file that includes the right atom names. It must be in PDB format with CONECT entries", metavar="PDBfile")
parser.add_argument("-f", dest="fixedPDB", required=True,
                    help="File to write fixed PDB, i.e., the query file with the correct atom names", metavar="PDBfile")

args = parser.parse_args()
Query    = args.queryPDB
Template = args.templatePDB
Fixed    = args.fixedPDB


#---------------------------------------
#     Known issues
#---------------------------------------
print " MolRenamer - PDBwPDB"
print ""
print "Info)"
print "   - Atom indices must be unique."
print "   - Atom name must be unique."
print "   - Conectivity must be correct -except for H atoms- (check visually with Pymol,VMD, etc.)."
print "   - CONECT lines must be after all HETATM lines."
print "   - The template must contain all the atoms in the query file."
print "   - This algorithm assigns atom names by their conectivity. It can happen with highly"
print "     simmetric molecules that the script fails to get the right naming. When this happens"
print "     the molecule is not fully translated. Always check with you preferred visualizer."
print ""


#---------------------------------------
#      Parameters 
#---------------------------------------
MaxLayer = 6

#---------------------------------------
#    Read TEMPLATE
#       TemplateList will contain all the data assigned to atoms 
#       in the template file. 
#       - Atom Name
#       - Atom Type (atom & charge)
#       - Conection by Atom Name (sublist)
#---------------------------------------

d1 = {}     #  ID       --> name
d2 = {}     #  name --> type 
d3 = {}     #  name --> bonds

for line in open(Template):

    if line[0:6] == 'HETATM':
        line = line.strip('\n')
        if len(line) != 80:
            sys.exit('Error in file '+Template+'. All lines should have 80 characters. Check white spaces.\n'+line+'\n')


        ID   = int( line[6:11] )
        name = "-".join([ line[12:16],line[17:20] ])
        type = line[76:80]

        d1[ID]   = name
        if name in d2.keys():
           sys.exit('Error. Atom name/residue '+name+' in file '+Template+' is not unique.') 
        d2[name] = type

        continue

    if line[0:6] == 'CONECT':

        ID = int(line.split()[1])
        name = d1[ID]
        bonds = []
        for i in map(int, line.split()[2:]):
            if d2[d1[i]][0:2] == ' H':
                continue
            bonds.append( d1[i] ) 
        d3[name] = bonds 

dTemplate={}
dTemplate['ID->name'] = d1
dTemplate['name->type'] = d2
dTemplate['name->bonds'] = d3

# Checking lengths
print 
if ( (len(dTemplate['ID->name']) != len(dTemplate['name->type']))
  or  (len(dTemplate['name->type']) != len(dTemplate['name->bonds']))): 
    sys.exit('Error. Different number of HETATM and CONECT in '+Template)

# Uncoment to see the atoms
#for ID in dTemplate['ID->name'].keys():
#    name  = dTemplate['ID->name'][ID]
#    type  = dTemplate['name->type'][name]
#    bonds = dTemplate['name->bonds'][name]
#    print ID,name,type,bonds

#--------------------------------------
#    Read QUERY
#       QueryList will contain all the data assigned to atoms 
#       in the template file. 
#       - Atom Name
#       - Atom Type (atom & charge)
#       - Conection by Atom Name (sublist)
#--------------------------------------

d1 = {}     #  ID       --> name
d2 = {}     #  name --> type 
d3 = {}     #  name --> bonds
d4 = {}     #  name --> linestring
for line in open(Query):

    if line[0:6] == 'HETATM':
        line = line.strip('\n')
        if len(line) != 80:
            sys.exit('Error in file '+Query+'. All lines should have 80 characters. Check white spaces.\n'+line+'\n')

        ID   = int( line[6:11] )
        name = "-".join([ line[12:16],line[17:20] ])
        type = line[76:80]

        d1[ID]   = name
        if name in d2.keys():
           sys.exit('Error. Atom name/residue '+name+' in file '+Query+' is not unique.')
        d2[name] = type
        d4[name] = line

        continue

    if line[0:6] == 'CONECT':

        ID = int(line.split()[1])
        name = d1[ID]

        bonds = []
        for i in map(int, line.split()[2:]):
            if d2[d1[i]][0:2] == ' H':
                continue
            bonds.append( d1[i] ) 

        d3[name] = bonds

dQuery={}
dQuery['ID->name']    = d1
dQuery['name->type']  = d2
dQuery['name->bonds'] = d3
dQuery['name->line']  = d4

# Checking lengths
if ( (len(dQuery['ID->name']) != len(dQuery['name->type']))
  or  (len(dQuery['name->type']) != len(dQuery['name->bonds']))):
    sys.exit('Error. Different number of HETATM and CONECT in '+Template)

# Uncoment to see the atoms
#for ID in dQuery['ID->name'].keys():
#    name  = dQuery['ID->name'][ID]
#    type  = dQuery['name->type'][name]
#    bonds = dQuery['name->bonds'][name]
#    line  = dQuery['name->line'][name]
#    print ID,name,type,bonds,line



#-------------------------------------
#     Functions
#-------------------------------------

def get_net(level,name,Dict):
    if   level == 0:
        layer = Dict['name->type'][name]
        return layer

    elif level == 1:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            layer.append(Dict['name->type'][name1])
        return layer

    elif level == 2:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            bonds1 = Dict['name->bonds'][name1]
            layer1 = []
            for name2 in bonds1:
                layer1.append(Dict['name->type'][name2])
            layer.append(layer1)
        return layer


    elif level == 3:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            bonds1 = Dict['name->bonds'][name1]
            layer1 = []
            for name2 in bonds1:
                bonds2 = Dict['name->bonds'][name2]
                layer2 = []
                for name3 in bonds2:
                    layer2.append(Dict['name->type'][name3])
                layer1.append(layer2)
            layer.append(layer1)
        return layer

    elif level == 4:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            bonds1 = Dict['name->bonds'][name1]
            layer1 = []
            for name2 in bonds1:
                bonds2 = Dict['name->bonds'][name2]
                layer2 = []
                for name3 in bonds2:
                    bonds3 = Dict['name->bonds'][name3]
                    layer3 = []
                    for name4 in bonds3:
                        layer3.append(Dict['name->type'][name4])
                    layer2.append(layer3)
                layer1.append(layer2)
            layer.append(layer1)
        return layer

    elif level == 5:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            bonds1 = Dict['name->bonds'][name1]
            layer1 = []
            for name2 in bonds1:
                bonds2 = Dict['name->bonds'][name2]
                layer2 = []
                for name3 in bonds2:
                    bonds3 = Dict['name->bonds'][name3]
                    layer3 = []
                    for name4 in bonds3:
                        bonds4 = Dict['name->bonds'][name4]
                        layer4 = []
                        for name5 in bonds4:
                            layer4.append(Dict['name->type'][name5])
                        layer3.append(layer4)
                    layer2.append(layer3)
                layer1.append(layer2)
            layer.append(layer1)
        return layer

    elif level == 6:
        bonds = Dict['name->bonds'][name]
        layer = []
        for name1 in bonds:
            bonds1 = Dict['name->bonds'][name1]
            layer1 = []
            for name2 in bonds1:
                bonds2 = Dict['name->bonds'][name2]
                layer2 = []
                for name3 in bonds2:
                    bonds3 = Dict['name->bonds'][name3]
                    layer3 = []
                    for name4 in bonds3:
                        bonds4 = Dict['name->bonds'][name4]
                        layer4 = []
                        for name5 in bonds4:
                            bonds5 = Dict['name->bonds'][name5]
                            layer5 = []
                            for name6 in bonds5:
                                layer5.append(Dict['name->type'][name6])
                            layer4.append(layer5)
                        layer3.append(layer4)
                    layer2.append(layer3)
                layer1.append(layer2)
            layer.append(layer1)
        return layer



def equal_layers(level,netA,netB):
    if   level == 0:
        answer = (netA == netB)
        return answer


    elif level == 1:
        answer = (collections.Counter(netA) == collections.Counter(netB))
        return answer


    elif level == 2:
        answer = True

        Ap = copy.deepcopy(netA)
        Bp = copy.deepcopy(netB)
       
        if len(Ap) != len(Bp):
            answer = False
            return answer

        for i in range(len(Ap)):
            sublayerAp = Ap.pop(0)
            ListFound=-99
            for j in range(len(Bp)):
                if equal_layers(1,sublayerAp,Bp[j]): 
                    ListFound=j
                    break
            if ListFound == -99:
                answer = False
                return answer
            else:
                Bp.pop(j)

        return answer
        

    elif level == 3:
        answer = True

        Ap = copy.deepcopy(netA)
        Bp = copy.deepcopy(netB)

        if len(Ap) != len(Bp):
            answer = False
            return answer
        
        for i in range(len(Ap)):
            sublayerAp = Ap.pop(0)
            ListFound=-99
            for j in range(len(Bp)):
                if equal_layers(2,sublayerAp,Bp[j]): 
                    ListFound=j
                    break
            if ListFound == -99:
                answer = False
                return answer
            else:
                Bp.pop(j)

        return answer



    elif level == 4:
        answer = True

        Ap = copy.deepcopy(netA)
        Bp = copy.deepcopy(netB)

        if len(Ap) != len(Bp):
            answer = False
            return answer

        for i in range(len(Ap)):
            sublayerAp = Ap.pop(0)
            ListFound=-99
            for j in range(len(Bp)):
                if equal_layers(3,sublayerAp,Bp[j]):
                    ListFound=j
                    break
            if ListFound == -99:
                answer = False
                return answer
            else:
                Bp.pop(j)

        return answer


    elif level == 5:
        answer = True

        Ap = copy.deepcopy(netA)
        Bp = copy.deepcopy(netB)

        if len(Ap) != len(Bp):
            answer = False
            return answer

        for i in range(len(Ap)):
            sublayerAp = Ap.pop(0)
            ListFound=-99
            for j in range(len(Bp)):
                if equal_layers(4,sublayerAp,Bp[j]):
                    ListFound=j
                    break
            if ListFound == -99:
                answer = False
                return answer
            else:
                Bp.pop(j)

        return answer

    elif level == 6:
        answer = True

        Ap = copy.deepcopy(netA)
        Bp = copy.deepcopy(netB)

        if len(Ap) != len(Bp):
            answer = False
            return answer

        for i in range(len(Ap)):
            sublayerAp = Ap.pop(0)
            ListFound=-99
            for j in range(len(Bp)):
                if equal_layers(5,sublayerAp,Bp[j]):
                    ListFound=j
                    break
            if ListFound == -99:
                answer = False
                return answer
            else:
                Bp.pop(j)

        return answer



def equal_nets(MaxLayer,nameA,A,nameB,B):
    answer = True

    for level in range(MaxLayer+1):
        netA = get_net(level,nameA,A)
        netB = get_net(level,nameB,B)
        answer = equal_layers(level,netA,netB)

#        FOR TROUBLESHOOTING...
#        print "COMPARING:", nameA, nameB
#        print "LEVEL:", level
#        print netA
#        print netB
#        print "ANSWER:", answer
#        if answer == False:
#            print "------------------------------------------------------------------------"
#        else:
#            print ""
#        if level == 6:
#            print "------------------------------------------------------------------------"
#            print "------------------------------------------------------------------------"
#            print "------------------------------------------------------------------------"
       

        if answer == False:
            return answer

    return answer


#-------------------------------------------------------
#    Comparison
#-------------------------------------------------------
dQuery['name->nameTemplate'] = {}
d5={}

TmpDict = copy.deepcopy(dTemplate['name->type'])

for nameQ in dQuery['name->type'].keys():
    for nameT in TmpDict.keys():
        if equal_nets(MaxLayer,nameQ,dQuery,nameT,dTemplate):
            d5[nameT] = nameQ
            del TmpDict[nameT]
            break
        
    
dQuery['nameTemplate->name'] = d5


#---------------------------------------
# Write Output
#---------------------------------------
fixedfile=open(Fixed,'w')

for line in open(Template):

    if line[0:6] == 'HETATM':
        line = line.strip('\n')
        nameT = "-".join([ line[12:16],line[17:20] ])
        if nameT in dQuery['nameTemplate->name'].keys():
            nameQ = dQuery['nameTemplate->name'][nameT]
            name = nameT.split('-')
            line  = dQuery['name->line'][nameQ]
            fixedfile.write(line[0:12]+name[0]+line[16]+name[1]+line[20:80]+'\n')

fixedfile.close()
