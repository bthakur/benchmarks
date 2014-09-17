#!/bin/bash

  source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh
  source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64

mpirun -genv I_MPI_FABRICS shm:tcp -genv I_MPI_DEBUG 50 -genv I_MPI_MIC_POSTFIX .mic -machinefile ../all /home/bthakur/run_symmetric/f90/bin/hello
