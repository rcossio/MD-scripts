name=system
prmtop=system.prmtop
mask="@CA"
representative=$name.representative.pdb
showmask="!(:Na+,Cl-)"
seq=$(seq 200 1 600)

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

#---------------------------------------
#  Get the most representative
#---------------------------------------
frame=$(grep -v "#" | sort -rnk2 tmp.rmsd.dat| awk '{print $1}')
rmsd=$(grep -v "#" | sort -rnk2 tmp.rmsd.dat| awk '{print $2}')

echo "#Comment" > tmp.script
for i in $seq
do
    echo "trajin $name.pro.$i.nc" >> tmp.script
done
cat >> tmp.script <<EOF
strip !($showmask)
trajout $representative onlyframes $frame nobox
strip !($mask)
trajout tmp.representative.pdb nobox
go
quit
EOF
cpptraj $prmtop tmp.script
rm tmp.script


#----------------------------
#	Check right RMSD
#----------------------------
cat > tmp.script <<EOF
trajin tmp.representative.pdb
reference tmp.pdb
rms reference "*" mass out tmp.rmsd.dat
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

rmsd2=$(grep -v "#" | sort -rnk2 tmp.rmsd.dat| awk '{print $2}')

echo "RMSD: $rmsd  RMSD2: $rmsd2"
rm tmp.prmtop tmp.pdb
