
NAME=ligand
CHARGE=-1
RESNAME=LIG

#----------------------------
# AM1-BCC charges and GAFF2
#----------------------------
pytleap --lig=$NAME.sdf --chrg=$CHARGE --lfrc=gaff2


#----------------------------
#  Minimization
#----------------------------
cat > $NAME.in <<EOF
Min in vacuo
 &cntrl
     IMIN = 1, NCYC = 1000, MAXCYC = 1000, NTB = 0, CUT = 999, NTPR = 10,
/
EOF

sander -O -i $NAME.in -o $NAME.min.mdout -p $NAME.leap.prm -c $NAME.leap.crd -r $NAME.min.crd
grep -A 1 ENERGY $NAME.min.mdout | grep -v ENERGY | grep -v "\-\-" > $NAME.min_energy.dat

cat > tmp.script << EOF
trajin $NAME.min.crd
trajout $NAME.min.pdb
go
quit
EOF
cpptraj $NAME.leap.prm tmp.script
rm tmp.script

#------------------------------
#  Creating OFF
#------------------------------
cat > tmp.leap.in << EOF
  source leaprc.gaff2
  LIT = loadmol2 $NAME.ac.mol2
  loadamberparams $NAME.leap.frcmod
  saveoff LIT $NAME.off
  quit
EOF
tleap -f tmp.leap.in
rm tmp.leap.in
sed -i "s/LIT/$RESNAME/g" $NAME.off

