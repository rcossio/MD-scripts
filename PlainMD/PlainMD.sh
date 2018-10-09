name=System.chosen
cuda=1
maxatoms=5790
prmtop=System.prmtop
cut=10

#--------------------------------------------------------------------------------------------------------------
for n in {1..600}
do

if [ "$n" == "1" ]
then
    inpcrd=$name.eq.6.crd
else
    inpcrd=$name.pro.$(($n-1)).crd
fi

input=$name.pro.$n.in
output=$name.pro.$n.out
outcrd=$name.pro.$n.crd
outnc=$name.pro.$n.nc
cat > $input << EOF
Equilibration
 &cntrl
  imin = 0, ntx=5, irest=1,
  ntb = 2, pres0=1.0, ntp=1,
  ntpr = 10000, ntwx = 10000, ntwr = 250000,
  ntt = 3, gamma_ln = 1, temp0 = 310.0,
  nstlim = 500000,
  ntc=2, ntf=2, dt = 0.002,
  cut = $cut,
  ioutfm = 1, ntwprt=$maxatoms,
 /
EOF
export CUDA_VISIBLE_DEVICES=$cuda
pmemd.cuda -O -i $input -o $output  -c $inpcrd -p  $prmtop -r $outcrd -x $outnc
done

