#python this.py amber.vecs VecID average.pdb scale > output

import sys
import numpy as np

PCAfile=open(sys.argv[1])
PCAfile.readline()
Dim=int(PCAfile.readline().split()[0])
N=int(sys.argv[2])-1
AveFile=sys.argv[3]
scale=float(sys.argv[4])

if Dim%7==0:
    Nlines = Dim/7
else:
    Nlines = Dim/7 +1

string= ''
for i in range(Nlines):
    string += PCAfile.readline().strip('\n')

Average = map(float,string.split())
if len(string.split()) != Dim: 
    sys.exit("Error. Not right dimension")


Eval=[]
Evec=[]
while PCAfile.readline().strip() == '****':
    Eval.append(float(PCAfile.readline().split()[1]))
    string= ''
    for i in range(Nlines):
        string += PCAfile.readline().strip('\n')

    if len(string.split()) != Dim: 
        sys.exit("Error. Not right dimension")
    Evec.append(map(float,string.split()))

for s in list(np.arange(-1,1.01,0.1)):
    v = Evec[N]
    k = s*scale*np.sqrt(Eval[N])
    m=0
    sys.stdout.write('MODEL\n')
    for line in open(AveFile):
        if line[0:4] == 'ATOM':
            x= Average[m]+k*v[m]
            y= Average[m+1]+k*v[m+1]
            z= Average[m+2]+k*v[m+2]
            sys.stdout.write(line[0:30]+"%8.3f%8.3f%8.3f"%(x,y,z)+line[54:])
            m += 3
        if line[0:3] == 'TER':
            sys.stdout.write(line)
    sys.stdout.write('ENDMDL\n')
sys.stdout.write('END\n')

