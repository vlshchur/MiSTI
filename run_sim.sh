#!/bin/sh
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 DIRECTORY \"ms arguments\"" >&2
  exit 1
fi 
DIR=$1
MSARG=$2
if [ -d "$DIR" ]; then
  echo "Cannot create the directory. Directory exists."
  exit 1
fi
`mkdir $DIR`
if [ ! -d "$DIR" ]; then
  echo "Failed to create the directory $DIR"
  exit 1
fi
./foreign/msHOT-lite/msHOT-lite $MSARG > $DIR/sim.ms
./MSSPLIT.py $DIR/sim.ms $DIR
/home/vladimir/psmc_project/psmc/utils/ms2psmcfa.pl $DIR/ms2g1.ms > $DIR/ms2g1.psmc.fa
/home/vladimir/psmc_project/psmc/utils/ms2psmcfa.pl $DIR/ms2g2.ms > $DIR/ms2g2.psmc.fa
#`/home/vladimir/psmc_project/psmc/psmc -p 1*4+25*2+1*4+1*6 $DIR/ms2g1.psmc.fa > $DIR/ms2g1.psm`
#`/home/vladimir/psmc_project/psmc/psmc -p 1*4+25*2+1*4+1*6 $DIR/ms2g2.psmc.fa > $DIR/ms2g2.psm`
parallel /home/vladimir/psmc_project/psmc/psmc "-p 1*4+25*2+1*4+1*6 $DIR/ms2g{}.psmc.fa > $DIR/ms2g{}.psmc" ::: 1 2
#parallel echo "-p 1*4+25*2+1*4+1*6 $DIR/ms2g{}.psmc.fa" ::: 1 2 > $DIR/ms2g{}.psmc
/home/vladimir/psmc_project/psmc/utils/psmc_plot.pl -n30 -u 6.83e-8 -g1 -x1 -X1000000 -L -M genome1,genome2, $DIR/plot_sim $DIR/ms2g1.psmc $DIR/ms2g2.psmc
./MS2JAF.py $DIR/sim.ms > $DIR/sim.jafs
