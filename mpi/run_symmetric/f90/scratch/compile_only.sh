#!/bin/bash

echo "+------------------+"
echo "| Setup compilers  |"
echo "+------------------+"

    #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh
    #source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
    source /usr/local/compilers/Intel/parallel_studio_xe_2015/impi/5.0.1.035/bin64/mpivars.sh
    source /usr/local/compilers/Intel/parallel_studio_xe_2015/composer_xe_2015.0.090/bin/compilervars.sh intel64

    mpiifort -fc=ifort hello_mpi.f90 -o hello
    mpiifort -fc=ifort reduce_mpi.f90 -o reduce

    mpiifort -fc=ifort -mmic hello_mpi.f90 -o hello.mic
    mpiifort -fc=ifort -mmic reduce_mpi.f90 -o reduce.mic

