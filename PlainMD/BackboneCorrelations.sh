name=system
prmtop=system.prmtop
mask="@CA"
output=$name.bb_corr.gnu

#--------------------------------------------
#    Strip atoms in MD
#--------------------------------------------
echo "#Comment" > tmp.script
for i in {200..600}
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
mask="*"

#-----------------------------------------
# Make a good refrence
#-----------------------------------------
cat > tmp.script <<EOF
trajin tmp.mdcrd
rms first "$mask" mass
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
rms reference "$mask" mass
average tmp.pdb
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

done

#---------------------------------------
#  Calculates correlations
#---------------------------------------

cat > tmp.script <<EOF
trajin tmp.mdcrd
reference tmp.pdb
rms reference "$mask"
atomiccorr "$mask" out $output byres
go
quit
EOF
cpptraj tmp.prmtop tmp.script
rm tmp.script

