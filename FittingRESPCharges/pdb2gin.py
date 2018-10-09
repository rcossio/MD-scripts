#python2 xyz2gin.py name.pdb > name.gin

import sys

def atom_type(x):
    if x == "C"  : return "C "
    if x == "A"  : return "C "
    if x == "N"  : return "N "
    if x == "O"  : return "O "
    if x == "P"  : return "P "
    if x == "S"  : return "S "
    if x == "H"  : return "H "
    if x == "F"  : return "F "
    if x == "I"  : return "I "
    if x == "NA" : return "N "
    if x == "OA" : return "O "
    if x == "SA" : return "S "
    if x == "HD" : return "H "
    if x == "Mg" : return "Mg"
    if x == "Mn" : return "Mn"
    if x == "Zn" : return "Zn"
    if x == "Ca" : return "Ca"
    if x == "Fe" : return "Fe"
    if x == "Cl" : return "Cl"
    if x == "Br" : return "Br"


sys.stdout.write('$RunGauss\n%Chk=tmp.chk\n%Mem=10GB\n%NProcShared=16\n#N B3LYP/6-31G* Integral=(Grid=UltraFine) Pop(MK,ReadRadii) SCF=XQC\nNoSymm IOp(6/33=2)\n\nCLR\n\n-1  1\n')

for line in open(sys.argv[1]):
	if line[0:4] != 'ATOM':
		continue
	cols = line.split()
	sys.stdout.write("%-8s%9.3f%9.3f%9.3f\n" %(atom_type(cols[10]),float(cols[5]), float(cols[6]), float(cols[7]) ))
sys.stdout.write('\n\n')
