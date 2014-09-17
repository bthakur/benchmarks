#!/bin/bash

#exe=/usr/local/packages/mvapich2/2.0/INTEL-14.0.2/libexec/mvapich2/osu_reduce
exe=/usr/local/packages/mvapich2/2.0/INTEL-14.0.2/libexec/mvapich2/osu_bw
out=$(basename "$exe")

echo "+------------------+"
echo "| PBS setup        |"
echo "+------------------+"

echo "  PBS Environment       $PBS_ENVIRONMENT"
echo "  PBS Number of Nodes   $PBS_NUM_NODES"
echo "  PBS Procs per Node    $PBS_NUM_PPN"

  #Check non-null
  if [ ! -n "$PBS_JOBID" ]; then
    echo "You are not using PBS, exiting !"
    exit
  fi

  PbsLogs="$HOME/.log/joboutput/$PBS_JOBID"
  PbsHosts="$PbsLogs/hosts"
  PbsPhis="$PbsLogs/phis"
  
  if [ ! -d "$PbsLogs" ]; then
    mkdir -p $PbsLogs
  fi

  if [ -e "$PbsHosts" ]; then
    rm "$PbsHosts"
  fi
    cat $PBS_NODEFILE|uniq > $PbsHosts


  if [ -e "$PbsPhis" ]; then
    rm "$PbsPhis"
  fi
  touch "$PbsPhis"
  for f in $(cat $PbsHosts); do
    echo "${f}p-mic0" >> "$PbsPhis"
    echo "${f}p-mic1" >> "$PbsPhis"
  done  

  cat $PbsHosts
  cat $PbsPhis
  
  ahost=$(head -1 $PbsHosts)
  bhost=$(tail -1 $PbsHosts)
  aphi=$(head -1 $PbsPhis)
  bphi=$(tail -1 $PbsPhis)

echo "+------------------+"
echo "| Setup compilers  |"
echo "+------------------+"
  export MV2_IBA_HCA=mlx4_0

  #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh
  #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
  #source /usr/local/compilers/Intel/parallel_studio_xe_2015/impi/5.0.1.035/bin64/mpivars.sh
  #source /usr/local/compilers/Intel/parallel_studio_xe_2015/composer_xe_2015.0.090/bin/compilervars.sh intel64
  #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/ifortvars.sh intel64
  #exit
  #module load mvapich2 intel
  echo "$exe"
  echo "$out"

  which mpirun
  mpirun -n 2 -hostfile $PbsHosts $exe |tee $out.out


