#!/bin/bash

echo "+------------------+"
echo "| Runtime variables|"
echo "+------------------+"
    nperhost=2
    nperphi=10
    ompthds_host=1
    ompthds_mic=1
    postfix_mic=".mic"
    phis_per_node=2

    exe_host="/home/$USER/run_symmetric/f90/bin/hello"
    exe_mic=${exe_host}.${postfix_mic}
    bootstrap="/home/$USER/run_symmetric/f90/bootstrap/bootstrap.sh"
 
echo "+------------------+"
echo "| TACC test        |"
echo "+------------------+"

    scomp=$(uname -n)
    b=${scomp/stampede/}
    if [ "$scomp" != "$b" ]; then
      echo "This is Stampede, populate list"
    fi
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
      PbsHosts="hosts"
      PbsPhis="phis"
      PbsMachinefile="all"
      if [ ! -e "$PbsHosts" ]; then
        hostname -s > "$PbsHosts"
      fi
      PbsNodes=$(cat $PbsHosts)
   fi
   if [ -n "$SLURM_JOBID" ]; then
      PbsLogs="$HOME/.log/joboutput/$SLURM_JOBID"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"
      #PbsNodes=$(scontrol show hostname)
   fi
   if [ -n "$PBS_JOBID" ]; then 
# Setup logs in ~/.log directory
      PbsLogs="$HOME/.log/joboutput/$PBS_JOBID"
      PbsHosts="$PbsLogs/hosts"
      PbsPhis="$PbsLogs/phis"
      PbsMachinefile="$PbsLogs/all"
      PbsNodes=$(cat "$PBS_NODEFILE")
   fi

