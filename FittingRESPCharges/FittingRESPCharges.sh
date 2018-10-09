#!/bin/bash

NAME=ligand

#--------------------------------------
# From PDB or XYZ generates G09 input
#--------------------------------------
#python2 xyz2gin.py $NAME.xyz > $NAME.gin
python2 pdb2gin.py $NAME.pdb > $NAME.gin


#----------------------------------------------------------
# Runs G09 and corrects the bug
#---------------------------------------------------------
rm tmp.chk
g09 < $NAME.gin > $NAME.log
bash fixreadinesp.sh $NAME.log > $NAME.2.gin
g09 < $NAME.2.gin > $NAME.2.log
bash fixreadinesp.sh $NAME.2.log > $NAME.3.log 
rm tmp.chk 

#------------------------------------------------------------
# Get ESP potentential and atom center (to chekc visually)
#------------------------------------------------------------
grep "Atomic Center"  $NAME.3.log | awk '{print $6,$7,$8}' > $NAME.centers.dat
grep "ESP Fit Center" $NAME.3.log | awk '{print $7,$8,$9}' > tmp1
grep " Fit    "       $NAME.3.log | awk '{print $3}' > tmp2
paste tmp1 tmp2 > $NAME.esp.dat
rm tmp1 tmp2

#----------------------------------
# Re-arrange charges
#----------------------------------
rm esp.dat
gfortran readit.f
grep "Atomic Center "               $NAME.3.log > a
grep "ESP Fit"                      $NAME.3.log > b
grep -E "Fit    | \*\*\*\*        " $NAME.3.log > c
./a.out <<< "$(cat a| wc -l),$(cat b | wc -l)"
rm -f a b c a.out readit.o
mv esp.dat tmp.esp.dat

#----------------------------------
# 2 step RESP fitting 
#----------------------------------
antechamber -i $NAME.3.log -fi gout -o $NAME.ac -fo ac
respgen -i $NAME.ac -o tmp.resp1.in -f resp1
respgen -i $NAME.ac -o tmp.resp2.in -f resp2
resp -O -i tmp.resp1.in -o tmp.resp1.out -p tmp.resp1.pch -t tmp.resp1.chg -e tmp.esp.dat -s tmp.resp1.esout
resp -O -i tmp.resp2.in -o tmp.resp2.out -p tmp.resp2.pch -t tmp.resp2.chg -e tmp.esp.dat -s tmp.resp2.esout -q tmp.resp1.chg
cp tmp.resp2.chg $NAME.chg
sed -i ':a;N;$!ba;s/\n/ /g' $NAME.chg > $NAME.linchg
antechamber -i $NAME.ac -fi ac -o $NAME.mol2 -fo mol2 -c rc -cf $NAME.chg -pf y
rm ANTECHAMBER_* ATOMTYPE.INF 
rm tmp.resp1.in tmp.resp2.in tmp.resp1.out tmp.resp2.out tmp.resp1.pch tmp.resp2.pch tmp.resp1.chg tmp.resp2.chg tmp.esp.dat tmp.resp1.esout tmp.resp2.esout


