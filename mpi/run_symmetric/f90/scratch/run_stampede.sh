#!/bin/bash

echo "+------------------+"
echo "| Runtime variables|"
echo "+------------------+"
    nperhost=20
    nperphi=60
    ompthds_host=1
    ompthds_mic=1
    postfix_mic=".mic"
    phis_per_node=2

    exe_host="$HOME/run_symmetric/f90/bin/hello"
    exe_mic="${exe_host}${postfix_mic}"
    bootstrap="$HOME/run_symmetric/f90/bootstrap/bootstrap.sh"
 
echo "+------------------+"
echo "| TACC test        |"
echo "+------------------+"

    scomp=$(uname -n)
    b=${scomp/stampede/}
    c=${scomp/smic/}
    if [ "$scomp" != "$b" ]; then
      echo "This is Stampede, populate list"
      phis_per_node=1
      export is_host_stampede=y
      module swap mvapich2 impi/4.1.3.049
    fi 
    if [ "$scomp" != "$c" ]; then
      echo "This is SuperMic, populate list"
      phis_per_node=2
      export is_host_smic=y
      echo $is_host_smic 
    fi
      echo smic $is_host_smic 
      echo stampede $is_host_stampede
    #exit 
echo "+------------------+"
echo "| PBS setup        |"
echo "+------------------+"
  # Check environment
    #echo "  PBS Environment       $PBS_ENVIRONMENT"
    #echo "  PBS Number of Nodes   $PBS_NUM_NODES"
    #echo "  PBS Procs per Node    $PBS_NUM_PPN"
  # Check non-null PBS  variables
    if [ ! -n "$PBS_JOBID" ] && [ ! -n "$SLURM_JOBID" ]; then
      echo "You are not using PBS, Using local hosts and phis !"
      PbsLogs="$HOME/.log/joboutput/00"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"
      if [ ! -e "hosts" ]; then
        hostname -s > tmp
      else
        cat hosts > tmp
      fi
   fi
   if [ -n "$SLURM_JOBID" ]; then
      PbsLogs="$HOME/.log/joboutput/$SLURM_JOBID"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"
      scontrol show hostname > tmp
   fi
   if [ -n "$PBS_JOBID" ]; then 
# Setup logs in ~/.log directory
      PbsLogs="$HOME/.log/joboutput/$PBS_JOBID"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"
      touch $PbsLogs/tmp
      cat "$PBS_NODEFILE" |uniq > tmp
   fi
  # Create unique host entries
    if [ ! -d "$PbsLogs" ]; then
        mkdir -p $PbsLogs
    fi
    if [ -e "$PbsHosts" ]; then
        rm "$PbsHosts"
    fi
  # Remove previous phi/all entries
      if [ -e "$PbsPhis" ]; then
        rm "$PbsPhis"
      fi
      if [ -e "$PbsMachinefile" ]; then
        rm "$PbsMachinefile"
      fi
      cp -v tmp $PbsLogs/hosts
      touch "$PbsPhis"
      touch "$PbsMachinefile"
  # Create all host and phi entries
    for f in $(cat $PbsHosts); do
      #for k in $(eval echo "{1..$nperhost}"); do
        echo "${f}:$nperhost" >> "$PbsMachinefile"
      #done
      for i in $(eval echo "{1..$phis_per_node}"); do
          j=$(echo "$i-1"|bc)
        #for g in $(eval echo "{1..$npermic}"); do

          if [ "$is_host_smic" == "y" ]; then
            echo "${f}p-mic$j:$nperphi" >> "$PbsMachinefile"
            echo "${f}p-mic$j" >> "$PbsPhis"
          else
            echo "${f}-mic$j:$nperphi" >> "$PbsMachinefile"
            echo "${f}-mic$j" >> "$PbsPhis"
          fi
        #done 
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
    cat $PbsPhis
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

  if [ "$is_host_stampede" = "y" ]; then
    export impi_top=/opt/apps/intel13/impi/4.1.0.030
    export compiler_top=/opt/apps/intel/13/composer_xe_2013.2.146
  fi
  if  [ "$is_host_smic" = "y" ]; then
        echo smic $is_host_smic 
        export impi_top=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048
        export compiler_top=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144
        source $impi_top/bin64/mpivars.sh
        source $compiler_top/bin/compilervars.sh intel64
  fi

echo "+----------------------------------+"
echo "| Run on hosts+Phis: Hello World ! |"
echo "+----------------------------------+"
  #export I_MPI_OFA_ADAPTER_NAME=mlx4_0
  #export I_MPI_FABRICS=shm:dapl
  export MIC_ENV_PREFIX=MIC
  export I_MPI_MIC_ENABLE="enable"
  #export I_MPI_PIN_DOMAIN=":"
  #export I_MPI_FABRICS=shm:dapl
  

  #Notes: 
  # -machinefile is NOT the same as -f/-hostfile:
  # only machinefile controls rank placement: differs mvapich2
  #export I_MPI_HCA_ADAPTER=mlx4_0
  #-genv I_MPI_OFA_ADAPTER_NAME mlx4_0 \
  #-genv_MPI_OFA_NUM_PORTS 2 \
  #-genv I_MPI_DAPL_PROVIDER ofa-v2-mlx4_0-1s \
  #  -genv  MV2_USE_APM 0 \
  #export MIC_USE_2MB_BUFFERS=64K
  #export I_MPI_FABRICS=shm:tcp
  #export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/intel/mic/coi/host-linux-release/lib
  #export PATH=$PATH:/opt/intel/mic/bin 

  #export DAPL_UCM_REP_TIME=8000
  #export DAPL_UCM_RTU_TIME=4000
  #export DAPL_UCM_RETRY=10
  #export I_MPI_MIC=1
 
  export MIC_ENV_PREFIX=MIC
  #export MIC_OMP_STACKSIZE=2M
  #export MIC_STACKSIZE=500M
  export I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1u 
  export I_MPI_OFA_ADAPTER_NAME=mlx4_0 
   #if false; then
 
  echo "$PbsMachinefile"
  mpiexec.hydra  \
  -genv I_MPI_DAPL_PROVIDER ofa-v2-mlx4_0-1u -genv I_MPI_OFA_ADAPTER_NAME mlx4_0 \
  -print-rank-map \
  -genv I_MPI_DEBUG 2  \
  -genv I_MPI_MIC_POSTFIX "$postfix_mic" \
  --bootstrap-exec "$bootstrap" \
  -machinefile "$PbsMachinefile" \
  "$exe_host"
  #fi
  sleep 2; wait
  mpicleanup --file PbsCleanup -t -p
  mpicleanup
  #exit
echo "+----------------------------------+"
echo "| Run on hosts+Phis: Reduction !   |"
echo "+----------------------------------+"

  exe_host="$HOME/run_symmetric/f90/bin/reduce"
  #export I_MPI_HCA_ADAPTER=mlx4_0
  #export MV2_USE_APM=0
  #export I_MPI_DAPL_PROVIDER_LIST=ofa-v2-mlx4_0-1,ofa-v2-scif0
  #export I_MPI_DAPL_TRANSLATION_CACHE=enable,disable
  #export I_MPI_FABRICS=shm:dapl
  #export I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1u
  #export I_MPI_OFA_ADAPTER_NAME=mlx4_0
  mpiexec.hydra  \
  -print-rank-map \
  -genv I_MPI_DAPL_PROVIDER ofa-v2-mlx4_0-1u -genv I_MPI_OFA_ADAPTER_NAME mlx4_0 \
  -env I_MPI_DEBUG 2  \
  -env I_MPI_MIC_POSTFIX $postfix_mic \
  --bootstrap-exec $bootstrap \
  -machinefile $PbsMachinefile \
  $exe_host
  sleep 2; wait
  #mpicleanup --file PbsCleanup -t -p
  #mpicleanup
