#!/bin/bash

echo "+------------------+"
echo "| Runtime variables|"
echo "+------------------+"
    npernode_host=2
    npernode_mic=1
    ompthds_host=1
    ompthds_mic=1
    postfix_mic=".mic"

    exe_host="/home/$USER/run_symmetric/mpi-intel-imb"
    exe_host="./IMB-MPI1-impi5"
    exe_mic=${exe_host}.${postfix_mic}
    bootstrap="/home/$USER/run_symmetric/mpi-intel-imb"
    

echo "+------------------+"
echo "| PBS setup        |"
echo "+------------------+"
  # Check environment
    echo "  PBS Environment       $PBS_ENVIRONMENT"
    echo "  PBS Number of Nodes   $PBS_NUM_NODES"
    echo "  PBS Procs per Node    $PBS_NUM_PPN"
  # Check non-null PBS  variables
    if [ ! -n "$PBS_JOBID" ]; then
      echo "You are not using PBS, exiting !"
      exit
    fi
  # Setup logs in ~/.log directory
    PbsLogs="$HOME/.log/joboutput/$PBS_JOBID"
    PbsHosts="$PbsLogs/hosts"
    PbsPhis="$PbsLogs/phis"
    PbsAllNodes="$PbsLogs/all"
    if [ ! -d "$PbsLogs" ]; then
      mkdir -p $PbsLogs
    fi
  # Create unique host entries
    if [ -e "$PbsHosts" ]; then
      rm "$PbsHosts"
    fi
    cat $PBS_NODEFILE|uniq > $PbsHosts
  # Create unique phi entries
    if [ -e "$PbsPhis" ]; then
      rm "$PbsPhis"
    fi
  # Create all host and phi entries
    if [ -e "$PbsAllNodes" ]; then
      rm "$PbsAllNodes"
    fi
    touch "$PbsPhis"
    touch "$PbsAllNodes"
    for f in $(cat $PbsHosts); do
      echo "${f}p-mic0" >> "$PbsPhis"
      echo "${f}p-mic1" >> "$PbsPhis"
    done  
  # Sanity check
    cat $PbsHosts
    cat $PbsPhis
    cat $PbsHosts $PbsPhis > $PbsAllNodes

echo "+------------------+"
echo "| Setup compilers  |"
echo "+------------------+"

    #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh
    #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
    source /usr/local/compilers/Intel/parallel_studio_xe_2015/impi/5.0.1.035/bin64/mpivars.sh
    source /usr/local/compilers/Intel/parallel_studio_xe_2015/composer_xe_2015.0.090/bin/compilervars.sh intel64

echo "+----------------------------------+"
echo "| Run on hosts+Phis: Hello World ! |"
echo "+----------------------------------+"

  mpiexec.hydra  \
  -env I_MPI_DEBUG 2  \
  -env I_MPI_MIC_POSTFIX "$postfix_mic" \
  --bootstrap-exec "$bootstrap" \
  -perhost "$npernode_host"\
  -f "$PbsAllNodes" \
  "$exe_host"
  sleep 2; wait
  exit

echo "+----------------------------------+"
echo "| Run on hosts+Phis: Reduction !   |"
echo "+----------------------------------+"

  exe_host="/home/$USER/run_symmetric/f90/reduce"

  mpiexec.hydra  \
  -env I_MPI_DEBUG 0  \
  -env I_MPI_MIC_POSTFIX $postfix_mic \
  --bootstrap-exec $bootstrap \
  -perhost $npernode_host \
  -f $PbsAllNodes \
  $exe_host
  sleep 2; wait


