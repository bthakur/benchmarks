#!/bin/bash -x

# +-----+
#  Cores: TotalCores
# +-----+
  export cores=64

# +-----+
#  Thds: OpenMPThreads
# +-----+

  export OMP_NUM_THREADS=4
  unset KMP_AFFINITY
  #export KMP_AFFINITY="granularity=thread,compact,verbose"

  let slots=$cores/$OMP_NUM_THREADS
  export slots


# +-----+
#  Host: Compiler/Mpi/Libs
# +-----+

  if [[ $Hs == "mike" || $Hs == "shelob" ]]; then

    #Top
      #top="/usr/local/packages/openmpi/1.6.5/Intel-13.0.0"
      #top="/usr/local/packages/mvapich2/1.9/Intel-13.0.0"
      #top="/usr/local/packages/openmpi/1.6.2/pgi-12.8"
      #top=/usr/local/packages/openmpi/1.6.2/gcc-4.7.2

    #Libs
      #MKLROOT="/usr/local/compilers/Intel/composer_xe_2013.0.079/mkl"
      #
      #libs="-I$MKLROOT/include/intel64 -L$MKLROOT/lib/intel64 -mkl=sequential"
      #
      #libs="-I$MKLROOT/include/intel64 -L$MKLROOT/lib/intel64 -mkl=sequential \
      #-L/usr/local/packages/perfsuite/1.1.2/Intel-13.0.0-openmpi-1.6.2/lib \
      #-L/usr/local/packages/papi/5.1.0.2/lib -lpshwpc_r "
      #-lperfsuite -lpapi -lexpat "
      #
      #libs="/usr/local/packages/lapack/3.4.0/pgi-12.8/lib/liblapack.a \
      #/usr/local/packages/lapack/3.4.0/pgi-12.8/lib/libblas.a"
      libs="/usr/local/packages/lapack/3.4.2/Intel-13.0.0/lib/liblapack.a \
            /usr/local/packages/lapack/3.4.2/Intel-13.0.0/lib/librefblas.a"
      #libs="/usr/local/packages/lapack/3.4.0/Intel-13.0.0/lib/liblapack.a \
      #/usr/local/packages/lapack/3.4.0/Intel-13.0.0/lib/libblas.a"
      #
      #  libs='-mkl'
    
    #Flags
      #fflags="-openmp -parallel -mavx -openmp-report2 -O3 -align array32byte"
       fflags="-openmp -parallel -mavx -openmp-report2 -O3 "
      #          -par-affinity=granularity=core,compact,verbose \"
      #fflags="-openmp -parallel -mavx -openmp-report2 -O3 -g -traceback -C -check all"
      #fflags=" -p -g -i_dynamic -mcmodel=medium -shared-intel -mavx -O3 -openmp -traceback -C"
      #fflags="-mavx -openmp -O3 -unroll-aggressive  -traceback -C"
      #fflags=" -O3 -C -acc -Mprof=time,ccff -Minfo=accel -ta=nvidia:kepler"
      #fflags=" -O3 -C -acc -Mprof=time,ccff -Minfo=accel -ta=nvidia"
      #fflags="-w -O3 -C -Mprof=time,ccff"

  elif [ $Hs == "philip" ]; then
      top="/usr/local/packages/openmpi/1.4.3/intel-11.1"
      libs="/usr/local/packages/lapack/3.4.0/intel-11.1/lib/liblapack.a \
            /usr/local/packages/lapack/3.4.0/intel-11.1/lib/libblas.a"
      fflags="-openmp -parallel -mavx -openmp-report2 -O3 -g -traceback -C -check all"

  elif [ $Hs == "pandora" ]; then
      echo Server needs work;
      exit;

  elif [ $Hs == "qb" ]; then
      echo Server needs work;
      exit;

  elif [[ $Hs == "hopper" ]]; then
      echo Server needs work;
      top="/opt/cray/xt-asyncpe/5.23"
      #top="/opt/cray/craype/2.1.1"
      libs=""
      fflags="-O3"
      mpf90="$top/bin/ftn"
      mprun="aprun"

  elif [[ $Hs == "edison" ]]; then
      echo Server needs work;
      #top="/opt/cray/xt-asyncpe/5.23"
      top="/opt/cray/craype/2.1.1"
      libs=""
      fflags="-O3"
      mpf90="$top/bin/ftn"
      mprun="aprun"
      #exit;

  elif [[ $Hs == "genepool" ]]; then
      top="/usr/common/usg/hpc/openmpi/gnu4.6/sge/1.6.5/ib_2.1-1.0.0"
      libs="/usr/lib/atlas-base/atlas/liblapack.so.3gf.0 \
	    /usr/lib/atlas-base/atlas/libblas.so.3gf.0"
      fflags="-fopenmp"
  else
      echo $Hs
      echo Unknown Server;
      exit
  fi


  if [ -z $mpf90 ]; then
      mpf90="$top/bin/mpif90"
      #which mpirun
      mprun="$top/bin/mpirun"
      #which mpif90
      echo $mpf90 $mprun
  fi

#$mpf90 -show

echo $mpf90
echo $mprun

#exit
#echo $libs
echo $fflags

#src=omp_1.14_acc1.f90
#src="timing_lapack.f90 omp_1.15.f90" #shaves off a few seconds
#codetop=/project/bthakur/benchmarks_builds/lanczos
#codetop=$HOME/lanczos
codetop=$(pwd)

src="$codetop/src/timing_lapack.f90 $codetop/src/omp_1.16.f90"

##$mpf90  -openmp -parallel -vec-report6 -openmp-report2 -O3 -g -traceback -C \
$mpf90   $fflags \
  $src -o $codetop/bin/$Hs.lanczos \
 -I$top/include \
 $libs


ls -l $codetop/bin/$Hs.lanczos

if [ -z $PBS_NODEFILE ]; then
   echo Make your own hostfile
else
   #cat $PBS_NODEFILE|uniq |tee $Hs.hosts 
   #sed -i "s/$/ slots=$slots max-slots=$slots /g" $Hs.hosts
   if [ -f $Hs.hosts ]; then
      echo file exists
      rm $Hs.hosts
   fi
   #
   touch $Hs.hosts
   #
   cat $PBS_NODEFILE|uniq > nodefile
   nodes=$(uniq nodefile|wc -l)
   for f in $(cat nodefile); do
     for ((h=1;h<=$slots;h++)); do
         echo $f >> $Hs.hosts
     done
   done
   cat $Hs.hosts
   #
   lines=$(cat ${Hs}.hosts|wc -l)
   let nmpi=$lines
   let N=$nmpi*$OMP_NUM_THREADS
   #let mrow=$nmpi*$OMP_NUM_THREADS
   echo MPI_tot: OMP :: $nmpi:$OMP_NUM_THREADS
fi


unset KMP_AFINITY
#KMP_AFFINITY='granularity=thread,scatter,verbose'; export KMP_AFFINITY; \

runstring="
time $mprun \\
--prefix $top \\
 -tag-output -num-sockets 2 -report-bindings -display-map \\
-x OMP_NUM_THREADS -np $slots \\
"

#OMP_NUM_THREADS=$OMP_NUM_THREADS; export OMP_NUM_THREADS; \
#KMP_AFFINITY=''; export KMP_AFFINITY; \
#-x KMP_AFFINITY \
#-hostfile $Hs.hosts \

sh -c "$runstring sleep 2" >& pre.out
sort -nk4 pre.out

cat << EOF |tee scratch/mpijob.sge

#!/bin/bash
#
#$ -l -pe pe_slots $cores
#$ -l q long_excl.q
#$ -l h_rt=230:00:00
#$ -j y
#$ -cwd
#$ -b y

top="$top"

Cores=$cores
OMP_NUM_THREADS=$OMP_NUM_THREADS
slots=$slots

export OMP_NUM_THREADS

$runstring $codetop/bin/$Hs.lanczos

EOF

echo "Look in scratch/mpijob.sge"

#echo "$runstring $codetop/bin/$Hs.lanczos |tee $Hs.n$nodes.p$nmpi.omp$OMP_NUM_THREADS.N${N}e6.D100"

#param=" --mca mpi_leave_pinned 0"
#param="-mca mpi_show_mca_params enviro"
#$mprun -np 128 -hostfile $PBS_NODEFILE -x MXM_SHM_RX_MAX_BUFFERS=32768 -mca mpi_show_mca_params enviro ./a.out
#$mprun -np 8 ./a.out
