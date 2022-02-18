#!/bin/bash

#I have forgotthen what was the idea behind this, I keep this file for bash syntax examples mainly

# 1. Reading arguments
while [[ $# -ge 1 ]]
do
case "$1" in

  -h|--help)  
  echo " 
  ACCURATE - Automated Convergent Centroid-based Umbrella-sampling ... etc 
  Usage:
             ./ACCUrate.sh --prmtop 1XEP.prmtop --cuda  "0 1" --head 0 --iter 1 50  --prefix _TEMP_ \
                           --output 1XEP.i  --values 0.0 0.5 3.0  --cut 10.0 --temp 283.15          \
                           --nsteps 10000 --nprint 10000  --nsamp 50  --nsave 1000       \
                           --seeds 1XEP.seed.l3.t100   --list 0.05,0.4,0.6,0.95             \
                           --g1 "1214,1322,1377,1393,1563,1573,1606,1623,1736,1828"  \
                           --g2 "2602,2603,2604,2605,2606,2607,2608,2609"
  "
  exit
  shift ;;

  --cuda)   CUDA=$2  ; shift ;;

  --iter)   ITER0=$2 ; shift ; ITERF=$2; shift ;;

  --prmtop) PRMTOP=$2; shift ;;

  --prefix) PREFIX=$2; shift ;;

  --out)    OUTPUT=$2; shift ;;

  --values) VAL0=$2  ; shift ; DVAL=$2 ; shift ; VALF=$2; shift ;;

  --cut)    CUT=$2   ; shift ;;

  --temp)   TEMP=$2  ; shift ;;

  --nsteps) NSTEPS=$2; shift ;;

  --nprint) NPRINT=$2; shift ;;

  --nsave)  NSAVE=$2 ; shift ;;

  --nsamp)  NSAMP=$2 ; shift ;;

  --seeds)  SEEDS=$2 ; shift ;;

  --head)   HEAD=$2  ; shift ;;

  --list)   LIST=$2  ; shift ;;

  --g1)     GROUP1=$2; shift ;;

  --g2)     GROUP2=$2; shift ;;

  *)
  (>&2  echo "ERROR: Argument $1 was not understood") && exit 
  ;;

esac
shift 
done




# 2. Checking existence of variables
ERROR=false
for var in "$CUDA"   "$ITER0"  "$ITERF"  "$PRMTOP" "$PREFIX" \
           "$OUTPUT" "$VAL0"   "$DVAL"   "$VALF"   "$CUT"    \
           "$TEMP"   "$NSTEPS" "$NPRINT" "$NSAVE"  "$NSAMP"  \
           "$SEEDS"  "$HEAD"   "$LIST"   "$GROUP1" "$GROUP2"
do
    [ -z "$var" ] && (>&2  echo "ERROR: There are variables not set") &&  ERROR=true
done
$ERROR && exit




# 3. Report
echo "
    ACCURATE - Automated Convergent Centroid-based Umbrella-sampling ... etc 
 
    Using variables:
	CUDA   		$CUDA
	ITERATIONS   	$ITER0 $ITERF
	PRMTOP   	$PRMTOP
	PREFIX   	$PREFIX
	OUTPUT   	$OUTPUT
	VALUES 		$VAL0 $DVAL $VALF
	CUT 		$CUT
	TEMPERATURE	$TEMP
	NSTEPS   	$NSTEPS
	NPRINT   	$NPRINT
	NSAVE   	$NSAVE
	NSAMP   	$NSAMP
        SEEDS           $SEEDS
        HEAD            $HEAD
        LIST		$LIST
        GROUPS		$GROUP1
			$GROUP2

Calculation started on $(date)
"




# 4. Check conditions to start 
ls -1 $PREFIX* > /dev/null 2>&1
[ "$?" = "0" ] && echo "There are files named $PREFIX*" && exit


# Making python scripts
echo "
import numpy as np
import sys

name = []
d = []
for line in open(sys.argv[2]):
    if line[0] == '#': continue 
    d.append(float(line.split()[1]))
    name.append(line.split()[0])
d = np.array(d,dtype=np.float32)


t = []
for line in open(sys.argv[1]):
    t.append(float(line.split()[1]))

t = np.array(t,dtype=np.float32)

h,x = np.histogram( t, bins = 50, normed = True )
dx = x[1] - x[0]
F = np.cumsum(h)*dx

output = open(sys.argv[3],'w')
output.write("#     Coord      Prob  Cumulative \n")
for i in range(len(h)):
    output.write(" %10.4f %10.4f %10.4f \n"%((0.5*x[i]+0.5*x[i+1]),h[i],F[i]))
output.close()

elist = []
for k in \[$LIST\]:
    index=np.argmin(abs(F-k))
    elist.append(0.5*x[index]+0.5*x[index+1])

for e in elist:
    print name[np.argmin(abs(d-e))]
" > $PREFIX.representatives.py

echo "
#    python check_e.py    13.0 13.5 13.0.dat 13.5.dat 

import sys
import numpy as np
import os

Kspring=20.0
Kb=0.0019872041 #in kcal/(mol.K)
T=283.15 # in K
beta = 1/(Kb*T)
x=float(sys.argv[1])
y=float(sys.argv[2])

def go4it(i,j,tipo): 
    e = []
    w = []

    if tipo == 'inverse':
        nombre = sys.argv[4]
        ref = j
    else:
        nombre = sys.argv[3]
        ref = i
    count = 0
    for line in open(nombre):
         count += 1
         if count < 0: continue
         elif  count > 200000: break
          

         value = float(line.split()[1])
         e.append( value )
         w.append( (Kspring/2.)*((value-float(ref))**2 ))
    
    e = np.array(e,dtype=float)
    w = np.array(w,dtype=float)    
    
    p0e,axis = np.histogram(e,bins=np.arange(-0.5,26.0,0.05),density=True)
    ave = np.mean(np.exp(-beta*w))
    return p0e,axis,ave    
 
A = "%4.1f" %x
B = "%4.1f" %y
p0e,axis, ave0 = go4it(A,B,'normal')
p1e,axis, ave1 = go4it(A,B,'inverse')
e = 0.5*axis[0:-1]+0.5*axis[1:]
r0e = p0e*np.exp(beta*(Kspring/2.)*((e-float(A))**2 ))*ave0
#r0e /= np.sum(r0e)

r1e = p1e*np.exp(beta*(Kspring/2.)*((e-float(B))**2 ))*ave1
#r1e /= np.sum(r1e)


for i in range(len(list(e))):
    print "%8.4f %8.4f %8.4f %8.4f %8.4f %8.4f" %( e[i], 15*p0e[i]/np.sum(p0e), -(1/beta)*np.log(r0e[i]), 15*p1e[i]/np.sum(p1e), -(1/beta)*np.log(r1e[i]),np.log(p1e[i]/p0e[i])+beta*(Kspring/2.)*(((e[i]-float(B))**2 - (e[i]-float(A))**2))) 
" > $PREFIX.check.py




# 5. Functions
function create_rst {
echo "
 &rst
 iat=  -1,  -1,
 r1=-100, r2=$val, r3=$val, r4=100, rk2=10.0, rk3=10.0,
 igr1= $GROUP1,
 igr2= $GROUP2,
 &end
"  > $PREFIX.$thiscuda.RST
}



function create_input {
echo "
File created by ACCUrate
 &cntrl
  imin=0, irest=1, ntx=5,
  cut=$CUT,
  ntb=2, pres0=1.0,ntp=1,
  temp0=$TEMP, ntt=3,gamma_ln=0.3,
  nstlim=$NSTEPS, dt=0.002,
  ntpr=$NPRINT, ntwr=$NPRINT,
  ntwx=$NSAVE, ntwv=$NSAVE,
  ntc=2,ntf=2,
  ioutfm=1,
  nmropt=1,
 &end
 /
 &wt type='DUMPFREQ', istep1=$NSAMP, /
 &wt type='END', /
 DISANG=$PREFIX.$thiscuda.RST
 DUMPAVE=$OUTPUT/dat/$i.$n.$val.dat
" > $PREFIX.$thiscuda.in 
}

function make_plot {
[ "$val" == "$VAL0" ] && return 0
A=$(python -c "print $val-$DVAL")
B=$val
[ -f $PREFIX.xa ] && /bin/rm $PREFIX.xa
[ -f $PREFIX.xb ] && /bin/rm $PREFIX.xb

for file in $(ls $OUTPUT/dat/$i.*.$A.dat)
do
    tail -n +"$(($HEAD+1))" $file >> $PREFIX.xa
done

for file in $(ls $OUTPUT/dat/$i.*.$B.dat)
do
    tail -n +"$(($HEAD+1))" $file >> $PREFIX.xb
done

python $PREFIX.check.py $A $B $PREFIX.xa $PREFIX.xb > $PREFIX.dat 2> /dev/null
cp $PREFIX.dat $OUTPUT/plots/$i.$val.preplot.dat
echo "
    set terminal postscript eps color enhanced font 'Helvetica,15'
    set output '$OUTPUT/plots/$i.$val.eps'
    set grid
    set ytics autofreq 0.25
    set ytics autofreq 0.50
    set xrange [$(python -c "print $A-2*$DVAL"):$(python -c "print $B+2*$DVAL")]
    #set yrange [-3:3]
    p '$PREFIX.dat' u 1:2 w l not, \
      '$PREFIX.dat' u 1:3 w lp not,\
      '$PREFIX.dat' u 1:4 w l not, \
      '$PREFIX.dat' u 1:5 w lp not, \
      '$PREFIX.dat' u 1:6 w lp not
" > $PREFIX.gnu
gnuplot $PREFIX.gnu 2>&1 > /dev/null

}



function sample {
while true
do
    for cuda in $CUDA
    do
        if [ ! -f $PREFIX.busy.cuda.$cuda ] 
        then
            thiscuda=$cuda
            break 2
        else
            sleep 2
        fi
    done
done
echo "" > $PREFIX.busy.cuda.$thiscuda
echo "          $inpcrd in CUDA $thiscuda"
create_rst   
create_input 
echo "
export CUDA_VISIBLE_DEVICES=$thiscuda
pmemd.cuda   -O -i $PREFIX.$thiscuda.in -o $PREFIX.out -inf $PREFIX.mdinfo   \
              -p $PRMTOP -c $inpcrd -r $OUTPUT/crd/$i.$n.$val.nccrd  \
             -x $OUTPUT/traj/$i.$n.$val.nctraj -v $OUTPUT/traj/$i.$n.$val.ncvel
/bin/rm $PREFIX.busy.cuda.$thiscuda
/bin/rm $PREFIX.$thiscuda.in
/bin/rm $PREFIX.$thiscuda.RST
" > $PREFIX.sample.$thiscuda.sh
bash $PREFIX.sample.$thiscuda.sh & 
}




function get_structures {
[ -f $PREFIX.dat ] && /bin/rm $PREFIX.dat
for file in $(ls $OUTPUT/dat/$(($i-1)).*.$val.dat)
do
    tail -n +"$(($HEAD+1))" $file >> $PREFIX.dat
done

[ -f $PREFIX.script ] && /bin/rm $PREFIX.script
for file in $(ls $OUTPUT/traj/*.*.*.nctraj | grep -v $OUTPUT/traj/$i)
do
	echo " trajin $OUTPUT/traj/*.*.*.nctraj" >> $PREFIX.script
done
echo "
distance d0 @$GROUP1 @$GROUP2 out $PREFIX.coordinates
go
quit" >> $PREFIX.script
cpptraj $PRMTOP $PREFIX.script > /dev/null

python $PREFIX.representatives.py $PREFIX.dat $PREFIX.coordinates $OUTPUT/prob/$i.$val.h $LIST > $PREFIX.crdlist

m=1
for frame in $(cat $PREFIX.crdlist)
do
	echo "
	trajin $OUTPUT/traj/*.*.*.nctraj
	trajout $PREFIX.1.crd restart onlyframes $frame
	go
	quit
	" > $PREFIX.script
	cpptraj $PRMTOP $PREFIX.script > /dev/null

	echo "
	trajin $OUTPUT/traj/*.*.*.ncvel usevelascoords
	trajout $PREFIX.2.crd restart onlyframes $frame
	go
	quit 
	" > $PREFIX.script
	cpptraj $PRMTOP $PREFIX.script > /dev/null

	head -n -1 $PREFIX.1.crd >  $OUTPUT/inpcrd/$i.$m.$val.inpcrd
	tail -n +3 $PREFIX.2.crd >> $OUTPUT/inpcrd/$i.$m.$val.inpcrd
	tail -1    $PREFIX.1.crd >> $OUTPUT/inpcrd/$i.$m.$val.inpcrd
	/bin/rm $PREFIX.1.crd $PREFIX.2.crd

	m=$(($m+1))
done
}



# Creating folders
if [ ! -d $OUTPUT ] 
then 
	mkdir $OUTPUT 
	mkdir $OUTPUT/crd 
	mkdir $OUTPUT/traj 
	mkdir $OUTPUT/dat 
	mkdir $OUTPUT/plots 
	mkdir $OUTPUT/inpcrd 
	mkdir $OUTPUT/prob
fi



# Start main code
for i in $(seq $ITER0 1 $ITERF)
do
	echo "ITERATION NUMBER $i"
	if [ "$i" == "1" ] 
	then
		for val in $(seq $VAL0 $DVAL $VALF)
		do
                	echo "	VAL: $val"
                        n=1
			for inpcrd in $(ls $SEEDS/*.*.$val.nccrd)
			do
				sample
				n=$(($n+1))
			done
                        while true
                        do
				ls -1 $PREFIX.busy.cuda.* > /dev/null 2>&1
                                [ ! "$?" = "0" ] && break 

                        done
                        /bin/rm $PREFIX.sample.*.sh
                        make_plot
		done
		continue

	else	
		# Check if there are residue files if that iteration
                ls -1 $OUTPUT/traj/$i.* > /dev/null 2>&1
		[ "$?" = "0" ] && echo "There are files named $OUTPUT/traj/$i.*" && exit
                ls -1 $OUTPUT/inpcrd/$i.* > /dev/null 2>&1
                [ "$?" = "0" ] && echo "There are files named $OUTPUT/inpcrd/$i.*" && exit

                # Regular loop
		for val in $(seq $VAL0 $DVAL $VALF)
	        do
			echo "	VAL: $val"
			get_structures
                        n=1
			for inpcrd in $(ls $OUTPUT/inpcrd/$i.*.$val.inpcrd)
			do
				sample
       	        		n=$(($n+1))
			done
                        while true
                        do
                                ls -1 $PREFIX.busy.cuda.* > /dev/null 2>&1
                                [ ! "$?" = "0" ] && break

                        done
                        /bin/rm $PREFIX.sample.*.sh
                        make_plot
	        done
	fi
done

echo "Calculation ended on $(date)"



# Erasing temprary files
/bin/rm $PREFIX.in  
/bin/rm $PREFIX.mdinfo  
/bin/rm $PREFIX.out  
/bin/rm $PREFIX.RST 
/bin/rm $PREFIX.coordinates 
/bin/rm $PREFIX.crdlist 
/bin/rm $PREFIX.dat 
/bin/rm $PREFIX.gnu 
/bin/rm $PREFIX.script 
/bin/rm $PREFIX.xa $PREFIX.xb
