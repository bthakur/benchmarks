#!/bin/bash

echo "+------------------+"
echo "| Runtime variables|"
echo "+------------------+"
    nperhost=4
    nperxphi=4
    ompthds_host=1
    ompthds_mic=1
    postfix_mic=".mic"
    phis_per_node=2

    exe_host="$HOME/run_symmetric/f90/bin/reduce"
    exe_mic="${exe_host}${postfix_mic}"
    bootstrap="$HOME/run_symmetric/f90/bootstrap/bootstrap.sh"
 
echo "+------------------+"
echo "| TACC test        |"
echo "+------------------+"

    scomp=$(uname -n)
    b=${scomp/stampede/}
    c=${scomp/smic/}
    d=${scomp/bc/}}

    if [ "$scomp" != "$d" ]; then
      echo "This is Babbage, populate list"
      phis_per_node=2
      export is_host_babbage=y
      module swap mvapich2 impi/4.1.3.049
    fi 
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
    #exit 
echo "+------------------+"
echo "| PBS setup        |"
echo "+------------------+"
  # Check environment
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
        echo "${f}:$nperhost" >> "$PbsMachinefile"
      for i in $(eval echo "{1..$phis_per_node}"); do
          j=$(echo "$i-1"|bc)
          if [ "$is_host_smic" == "y" ]; then
            echo "${f}p-mic$j:$nperxphi" >> "$PbsMachinefile"
            echo "${f}p-mic$j" >> "$PbsPhis"
          else
            echo "${f}-mic$j:$nperxphi" >> "$PbsMachinefile"
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
  if  [ "$is_host_babbage" = "y" ]; then
    echo smic $is_host_babbage 
    export impi_top=/global/babbage/nsg/opt/intel/impi/4.1.3.048
    export compiler_top=/global/babbage/nsg/opt/intel/composerxe/composer_xe_2013_sp1.3.174
    source $impi_top/bin64/mpivars.sh
    source $compiler_top/bin/compilervars.sh intel64
  fi


echo "+----------------------------------+"
echo "| Run on hosts+Phis: Hello World ! |"
echo "+----------------------------------+"

  mpiexec.hydra  \
  -env I_MPI_DEBUG 0  \
  -genv I_MPI_DAPL_PROVIDER=ofa-v2-mlx4_0-1u -genv I_MPI_OFA_ADAPTER_NAME=mlx4_0 \
  -env I_MPI_MIC_POSTFIX $postfix_mic \
  -machinefile $PbsMachinefile \
  $exe_host

exit

