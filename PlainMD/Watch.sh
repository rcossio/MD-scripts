NAME=system
PRMTOP=system.dry.prmtop
MASK=':5-355@CA'
SEQ=$(seq 200 20 600)

PRMTOPBOX=system.prmtop
SEQBOX=$(seq 200 100 600)

#----------------------------------------------
#	Watch dry system
#----------------------------------------------
rm tmp.script
for i in $SEQ
do
    echo "trajin  $NAME.pro.$i.nc 100 100" >> tmp.script
done

cat >> tmp.script <<EOF
rms first "$MASK" mass 
strip :Na+,Cl-
strip "@H="
trajout $NAME.watch.pdb nobox
go
quit
EOF

cpptraj $PRMTOP tmp.script
rm tmp.script


#----------------------------------------------
#       Watch solvated system
#----------------------------------------------
rm tmp.script
for i in $SEQBOX
do
    echo "trajin  $NAME.pro.$i.crd 100 100" >> tmp.script
done

cat >> tmp.script <<EOF
rms first "$MASK" mass
autoimage 
strip "@H="
trajout $NAME.watch_box.pdb nobox
go
quit
EOF

cpptraj $PRMTOPBOX tmp.script
rm tmp.script

