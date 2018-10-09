name=system
prmtop=system.dry.prmtop
output=$name.hbonds.dat
seq=$(seq 200 1 600)
resseq=$(seq 1 1 300)
resoffset=0
mask=":LIG"
distance=2.5

#--------------------------------------
echo "#this is a comment line" > $output
for res in $resseq
do
	resnum=$(($res-$resoffset))    #put residue offset here
	echo "#this is a comment line" > tmp.script
	for i in $seq
	do
		    echo "trajin  $name.pro.$i.nc" >> tmp.script
	done
	echo "hbond    hb0 acceptormask  :$resnum@O=,N=,S   donormask    $mask@O=,N=,S=  avgout tmp.hbond.dat nointramol"  >> tmp.script
	echo "hbond    hb1 donormask     :$resnum@O=,N=,S=  acceptormask $mask@O=,N=,S=  avgout tmp.hbond.dat nointramol"  >> tmp.script
	echo "go" >> tmp.script
	echo "quit" >> tmp.script
	cpptraj $prmtop tmp.script
        rm tmp.script

	echo -n "$res " >> tmp.output
	awk '{S=S+$4}END{print S}' tmp.hbond.dat >> tmp.output
        echo "0.0" >> tmp.output


done

grep -v "#" tmp.output | awk '{printf $1, $2}' > $output
rm tmp.output


