# MiSTI
PSMC-based Migration and Split Time Inference (MiSTI) from two genomes

## Data preparation
1. Run PSMC (Li, Durbin 2011) on two genomes.
2. Generate joint site frequency spectrum of these genomes. If you use RealSFS (ANGSD), use the script utils/ANGSDSFS.py to convert it to MiSTI format
./utils/ANGSDSFS.py real.sfs [genome1_label genome2_label] > mi.sfs
where real.sfs is the filename generated by RealSFS. We recommend to add labels (names) for the genomes or their populations to keep a record of their order in the real.sfs.
Example:
./utils/ANGSDSFS.py Yoruba_French.real.sfs YRI FRE > Yoruba_French.mi.sfs
For simulated data use the scripts utils/MS2JAF.py (msHOT-lite with -l format) or utils/SCRM2JAF.py (regular ms of scrm output format) to calculate joint SFS from simulated chromosomes.
 * If one of the genomes is ancient, it should be the _second_ genome in SFS.

## On the time scale
The time scale used in MiSTI command line is based on the PSMC time discretisation. Usually the time discretisation for different genomes does not coinside, so MiSTI merges the time points from two psmc files. Hence, on each time interval the coalescence rates for both genomes are constant. All the times in MiSTI command line (except for the sample date in case of ancient genome) are the indices of the corresponding time intervals. Use utils/calc_time.py to convert indices to generations/years. Example:
./utils/calc_time.py genome1.psmc genome2.psmc
>0&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;0  
>1&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;235  
>2&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;335  
>3&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;492  
>4&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;699  
>5&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;771  
>...

For example, setting split time to 3 in the command line means that it is 492 generation/years ago.

## MiSTI command line

The minimal command line is
./MiSTI2.py genome1.psmc genome2.psmc mi.sfs split_time
where genome1.psmc and genome2.psmc are files with psmc output for two genomes and mi.sfs is the joint site frequency spectrum for these files in the special format used by MiSTI (see section _Data preparation - item 2_ above). split_time is the split time index (see section _On the time scale_ above).  
_NB: psmc files should be supplied in the same order as genomes appear in the sfs!_

### Migration bands
To add migration bands, __-mi__ option is used. It should be followed by 5 parameters (considered backward in time):  
   * migration source population (1 or 2): lineages from this population might migrate to the other population. If considered _forward_ in time, this is a recieving population.
   * migration start time (time interval index)
   * migration end time (time interval index)
     migration end time is _larger_ than migration start time
   * (initial) migration rate value
   * is it a fixed parameter (0) or optimised parameter (1). Optimised parameters are the parameters included in the numerical optimisation (Nelder-Mead local optimisation or bassin-hopping global optimisation).

Example:  
-mi 2 5 12 2.7 0 -mi 1 2 10 0.8 1
would create two migration bands. The first one is migration from the second population, between time intervals 5 and 12, the migration rate is fixed to 2.7. The second one is from population 1 between time intervals 2 and 10. It will be optimised starting with the initial value 0.8.

### Other command line parameters
* __-o output_file.mi__ will generate output file which can be used with plotting script.
* __-wd PATH__ can be used to set the working directory. Then psmc and sfs files will be read from that directory, the output file will be placed to this directory too.
* __-uf__ the flag to treat SFS as unfolded (genomes should be polarised by ancestral state prior to SFS calculation)
* __--sdate__ the dating of the ancient genome (ancient genome is always the second genome) in generations/years according to the time units used for rescaling (see _Setting time units_ section below.)
* __-rd NUM__ read round _NUM_ from PSMC files. By default the last round is read.

### Advanced command line parameters
* __-mth NUM__ NUM is between 0 and 1. The mixture treshold.
* __-tol NUM__ precision parameter of numerical optimisation.
* __--cpfit__ MiSTI approximated effective population sizes on each time interval either by fitting probabilities to coalesce or by fitting expected coalescence times (default).
* __--trueEPS__ treat input coalescence rates as the true effective population sizes (usually used for simulated data when true EPS are known.)
* __--nosmooth__

## Setting time units
In coalescence models, which are used by PSMC and MiSTI, all the parametes including times are set in units of a default effective population size N0. To rescale time axis to generations or years, one needs to set mutation rate per basepair per generation per haplotype, time per generation and bin size (used in PSMC). You can either edit the file setunits.txt or create a new file in the same format and use option --funits [custom_file_name.txt] to specify it.

## Running simulations
To run the simulations the shell script _run_sim.sh_ is provided. You need to install msHOT_lite simulator (Heng Li [github](https://github.com/lh3/foreign/tree/master/msHOT-lite)). On the lines 10 and 11 set the paths to msHOT-lite and PSMC on your machine. Gnu parallel is also used in the script (line 40) to run PSMC on two genomes in parallel. The following command will run the ms simulation, generate PSMC and sfs files and put them into the folder _simulated_scenario_  
_./run_sim.sh simulated_scenario "4 100 -t 15000 -r 1920 30000000 -l -I 2 2 2 -n 1 10 -n 2 4.5 -eN 0.025 0.2 -ej 0.045 2 1 -eN 0.175 3 -eN 0.625 1.8 -eN 3 3.2 -eN 8 5.5"_
Then you can run MiSTI
./MiSTI2.py ms2g1.psmc ms2g2.psmc sim.jafs 22 -o output.mi -uf

## MiSTI and Gnu parallel
If many models should be tested (e.g. to estimate the split time) we suggest to use gnu parallel. Example with a model with four migration bands (migration rates change at time interval {mc}):  
> parallel --header : -j 20 ./MiSTI2.py ms2g1.psmc ms2g2.psmc sim.jafs {st} -uf -o res.mi -wd data_sim/migr0_5 -mi 1 0 {mc} {mi1} 0 -mi 2 0 {mc} {mi2} 0 -mi 1 {mc} {st} {mi3} 0 -mi 2 {mc} {st} {mi4} 0 >> res.out ::: st 20 21 22 23 24 25 ::: mc 8 9 10 11 12 ::: mi1 00.0 00.5 02.0 05.0 ::: mi2 05.0 10.0 15.0 20.0 ::: mi3 00.0 00.5 02.0 05.0 ::: mi4 01.0 05.0 10.0 15.0  
> grep "migration rates = " res.out | sort -t "=" -rn -k5 | less

The second command sorts the scenarios by the best likelihood.
