#!/bin/bash

echo "+------------------+"
echo "| Runtime variables|"
echo "+------------------+"
    nperhost=2
    nperphi=1
    ompthds_host=1
    ompthds_mic=1
    postfix_mic=".mic"
    phis_per_node=2

    exe_host="/home/$USER/run_symmetric/f90/bin/hello"
    exe_mic=${exe_host}.${postfix_mic}
    bootstrap="/home/$USER/run_symmetric/f90/bootstrap/bootstrap.sh"
    

echo "+------------------+"
echo "| PBS setup        |"
echo "+------------------+"
  # Check environment
    echo "  PBS Environment       $PBS_ENVIRONMENT"
    echo "  PBS Number of Nodes   $PBS_NUM_NODES"
    echo "  PBS Procs per Node    $PBS_NUM_PPN"
  # Check non-null PBS  variables
    if [ ! -n "$PBS_JOBID" ]; then
      echo "You are not using PBS, Using local hosts and phis !"
      #exit
      PbsLogs="$HOME/.log/joboutput/00"
      PbsHosts="hosts"
      PbsPhis="phis"
      PbsMachinefile="all"
    else
  # Setup logs in ~/.log directory
      PbsLogs="$HOME/.log/joboutput/$PBS_JOBID"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"

  # Create unique host entries
      if [ ! -d "$PbsLogs" ]; then
        mkdir -p $PbsLogs
      fi
      if [ -e "$PbsHosts" ]; then
        rm "$PbsHosts"
      fi
    
    cat $PBS_NODEFILE|uniq > $PbsHosts 
    fi
  # Remove previous phi/all entries
      if [ -e "$PbsPhis" ]; then
        rm "$PbsPhis"
      fi
      if [ -e "$PbsMachinefile" ]; then
        rm "$PbsMachinefile"
      fi
      touch "$PbsPhis"
      touch "$PbsMachinefile"
  # Create all host and phi entries
    for f in $(cat $PbsHosts); do
        echo "${f}:$nperhost" >> "$PbsMachinefile"
      for i in $(eval echo "{1..$phis_per_node}"); do
          j=$(echo "$i-1"|bc)
          echo "${f}p-mic$j:$nperphi" >> "$PbsMachinefile"
          echo "${f}p-mic$j" >> "$PbsPhis"
      done
    done  
    local=$(uname -n)
    cat "$PbsHosts"|uniq|grep -v "$local" > PbsCleanup
    cat "$PbsPhis" |uniq >> PbsCleanup
    cat PbsCleanup
    
    nmpi=$(cat $PbsMachinefile|wc -l)

  # Sanity check
    echo "| --- Hosts --- |"
    cat $PbsHosts
    echo "| --- Hosts+Phis ---|"
    #cat $PbsPhis
    #cat $PbsHosts $PbsPhis > $PbsMachinefile
    cat "$PbsMachinefile"
    if [ "$?" != '0' ]; then
      echo "Error: $?"
      exit
    fi
    #exit
echo "+------------------+"
echo "| Setup compilers  |"
echo "+------------------+"

  source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh
  source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
  #source /usr/local/compilers/Intel/parallel_studio_xe_2015/impi/5.0.1.035/bin64/mpivars.sh
  #source /usr/local/compilers/Intel/parallel_studio_xe_2015/composer_xe_2015.0.090/bin/compilervars.sh intel64

echo "+----------------------------------+"
echo "| Run on hosts+Phis: Hello World ! |"
echo "+----------------------------------+"
  export I_MPI_OFA_ADAPTER_NAME=mlx4_0
  export I_MPI_FABRICS=shm:dapl
  export MIC_ENV_PREFIX=MIC
  export I_MPI_MIC_ENABLE="enable"
  export I_MPI_MIC=1
  export MIC_ENV_PREFIX=MIC
  export MIC_OMP_STACKSIZE=2M
  export MIC_STACKSIZE=500M
   #-genv I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1u -genv I_MPI_OFA_ADAPTER_NAME=mlx4_0 
   #if false; then
   mpirun  \
  -print-rank-map \
  -genv I_MPI_DEBUG 1  \
  -genv I_MPI_MIC 1 \
  -genv I_MPI_MIC_POSTFIX "$postfix_mic" \
  -machinefile "$PbsMachinefile" \
  "$exe_host"
  #fi
  sleep 2; wait
  #exit
  mpicleanup --file PbsCleanup -t -p
  mpicleanup
  #exit
echo "+----------------------------------+"
echo "| Run on hosts+Phis: Reduction !   |"
echo "+----------------------------------+"

  exe_host="/home/$USER/run_symmetric/f90/bin/reduce"
  #export I_MPI_DAPL_TRANSLATION_CACHE=enable,disable
  mpiexec.hydra  \
  -env I_MPI_DEBUG 0  \
  -genv I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1u -genv I_MPI_OFA_ADAPTER_NAME=mlx4_0 \
  -env I_MPI_MIC_POSTFIX $postfix_mic \
  -machinefile $PbsMachinefile \
  $exe_host
  sleep 2; wait
  #mpicleanup --file PbsCleanup -t -p
  #mpicleanup
