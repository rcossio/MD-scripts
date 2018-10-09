name=ROP-ATP.chosen.2
cuda=1
maxatoms=5790
prmtop=ROP-ATP.prmtop
cut=10
restraintmask='(:1-322)&!(@H=)'
eqsteps=250000
minrestraint=20.0
restraints=' 20.0 10.0  5.0  2.0 1.0  0.5  0.2  0.1  0.05'


# Minimization
#--------------------------------------------------------------------------------------------------------------
inpcrd=$name.ini.crd
input=$name.min.in
output=$name.min.out
outcrd=$name.min.crd
refcrd=$name.ini.crd

cat > $input << EOF
Restrained Minimization
 &cntrl
  imin=1, maxcyc=10000, ncyc=5000,
  ntpr=100,
  cut=$cut,
  ntb=1,
  ntr=1,restraintmask='$restraintmask',restraint_wt=$minrestraint,
 /
EOF
export CUDA_VISIBLE_DEVICES=$cuda
pmemd.cuda -O -i $input -o $output  -c $inpcrd -ref $refcrd -p $prmtop -r $outcrd 

grep -A 1 ENERGY $name.min.out | grep -v ENERGY | grep -v "\-\-" > $name.min_energy.dat

# Heating
#---------------------------------------------------------------------------------------------------------------------
inpcrd=$name.min.crd
refcrd=$name.min.crd
input=$name.heat.in
output=$name.heat.out
outcrd=$name.heat.crd

cat > $input << EOF
Heating
 &cntrl
  imin = 0, ntx=1, irest=0,
  ntb = 2, pres0=1.0, ntp=1, taup=0.5,
  ntpr = 50, ntwx = 0, ntwr = 50,
  ntt = 3, gamma_ln = 1, 
  tempi = 0.0, temp0 = 310.0,
  nstlim = 125000, 
  ntc=2, ntf=2, dt = 0.002,
  cut = $cut,
  ntr=1,restraintmask='$restraintmask',restraint_wt=$minrestraint,
  ioutfm = 1, nmropt=1,
 /
 &wt TYPE='TEMP0', ISTEP1=1,      ISTEP2=125000, VALUE1=0.0,  VALUE2=310.0,  /
 &wt TYPE='END' /
EOF
mxport CUDA_VISIBLE_DEVICES=$cuda
pmemd.cuda -O -i $input -o $output  -c $inpcrd -ref $refcrd -p $prmtop -r $outcrd 
#-----------------------------------------------------------------------------------------------------------------------------------
n=1

for wt in $restraints
do

if [ "$n" == "1" ]
then
    inpcrd=$name.heat.crd
else
    inpcrd=$name.eq.$(($n-1)).crd
fi

refcrd=$name.min.crd
input=$name.eq.$n.in
output=$name.eq.$n.out
outcrd=$name.eq.$n.crd

cat > $input << EOF
Equilibration
 &cntrl
  imin = 0, ntx=5, irest=1,
  ntb = 2, pres0=1.0, ntp=1,
  ntpr = 5000, ntwx = 0, ntwr = 15000,
  ntt = 3, gamma_ln = 1, temp0 = 310.0,
  nstlim = $eqsteps, 
  ntc=2, ntf=2, dt = 0.002,
  cut = $cut,
  ntr=1,restraintmask='$restraintmask',restraint_wt=$wt,
  ioutfm = 1, ntwprt=$maxatoms,
 /
EOF
export CUDA_VISIBLE_DEVICES=$cuda
pmemd.cuda -O -i $input -o $output  -c $inpcrd -ref $refcrd -p $prmtop -r $outcrd

((n++))
done
