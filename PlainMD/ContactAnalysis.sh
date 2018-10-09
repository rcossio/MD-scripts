name=system
prmtop=system.dry.prmtop
output=$name.contacts.dat
seq=$(seq 200 1 600)
resseq=$(seq 1 1 300)
resoffset=0
mask=":LIG"
distance=2.5

#--------------------------------------
#   Get contacts
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
	echo "nativecontacts   name c0 :$resnum "$mask" distance $distance writecontacts tmp.contacts savenonnative" >> tmp.script
	echo "go" >> tmp.script
	echo "quit" >> tmp.script
	cpptraj $prmtop tmp.script
        rm tmp.script

	echo -n "$res " >> tmp.output
	grep -v "#" tmp.contacts| awk '{S=S+$4}END{printf " "S" "}' >> tmp.output
	echo "0.0" >> tmp.output
	rm tmp.contacts
done

grep -v "#" tmp.output | awk '{printf $1, $2}' > $output
rm tmp.output

#---------------------------------------
#   Makes SVG for visualization
#---------------------------------------
grep -v "#" tmp.output | awk '{printf $2}' > tmp.matrix
python2 write_svg.py tmp.matrix > tmp.svg
rm tmp.matrix
