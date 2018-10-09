NAME=system
PRMTOP=system.dry.prmtop
MASK=':5-355@CA'
SEQ=$(seq 200 40 600)

#----------------------------------------------
rm tmp.script
for i in $SEQ
do
    echo "trajin  $NAME.pro.$i.nc 100 100" >> tmp.script
done

cat >> tmp.script <<EOF
reference $NAME.ini.pdb
rms first "$MASK" mass out $NAME.rmsd.dat 
rog "$MASK" mass out $NAME.rog.dat
go
quit
EOF

cpptraj $PRMTOP tmp.script

rm tmp.script

