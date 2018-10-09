name=system
prmtop=system.prmtop
mask="@CA"
seq=$(seq 200 1 600)
vectors=system.vecs
projection=system.proj
motions=system.motion
Nvecs=10
evals=$name.pca_evals.dat

#--------------------------------------------
#    Strip atoms in MD
#--------------------------------------------
echo "#Comment" > tmp.script
for i in $seq
do
    echo "trajin $name.pro.$i.nc" >> tmp.script
done
cat >> tmp.script <<EOF
strip !($mask)
trajout tmp.mdcrd 
go
quit
EOF
cpptraj $prmtop tmp.script
rm tmp.script

#----------------------------------------
# Make prmtop
#----------------------------------------
rm tmp.prmtop
ante-MMPBSA.py -p $folder/$prmtop -c tmp.prmtop -s "!($mask)"

#-----------------------------------------
# Make a good refrence
#-----------------------------------------
cat > tmp.script <<EOF
trajin tmp.mdcrd
rms first "*" mass
average tmp.pdb
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

for number in {1..25}
do

cat > tmp.script <<EOF
trajin tmp.mdcrd
reference tmp.pdb
rms reference "*" mass out tmp.rmsd.dat
average tmp.pdb
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

done

#-----------------------------------------------
# Make vectors
#----------------------------------------------
cat > tmp.script <<EOF
trajin tmp.A.mdcrd
reference tmp.pdb
rms reference "*" mass
matrix covar name covmat "*"
analyze matrix covmat vecs 100000000000 out $vectors
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

#-----------------------------------------------
# Projection
#----------------------------------------------
cat > tmp.script <<EOF
trajin tmp.mdcrd 
reference tmp.pdb
rms reference "*" mass
projection modes $vectors out $projection beg 1 end $Nvecs "$mask"
go
quit
EOF
cpptraj tmp.prmtop tmp.script

#------------------------------------------------
#	Acumulated fluctuartion
#------------------------------------------------
sum=$(grep -A 1 "\*\*\*" $vectors | grep -v -E "\*\*|\-\-" | awk '{S=S+$2} END {print S}')
grep -A 1 "\*\*\*" $vectors | grep -v -E "\*\*|\-\-" | awk -v sum=$sum '{print $1,$2,$2/sum}' > $evals 

#------------------------------------------------
# Create normalized motions
#------------------------------------------------
for i in {1..$Nvecs}
do
	python2 PCA-animate.py $vectors $i tmp.pdb > $motions.$i.pdb
done
rm tmp.prmtop tmp.script tmp.pdb tmp.mdcrd

