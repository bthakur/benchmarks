#!/bin/sh

export top=$(pwd)


source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh

mpf90=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/intel64/bin/mpif90
mpiexechydra=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/bin/intel64/mpiexec.hydra

#which ifort
mpiifort  hello_mpi.f90 -g -traceback -C -o $top/hello
#$mpf90  -fc=ifort hello_mpi.f90 -g -traceback -C -o $top/hello


phimpiprefix="./.MIC/"
phimpipostfix=".mic"
phimpipinmode="mpd"
hostmpimicenable="enable"
hostmpifabric="shm:tcp"  # works
hostmpifabric="shm:ofa" # ofa fabric is not available and fallback fabric is not enabled
hostmpifabric="shm:dapl" # DAT: library load failure: libdaplomcm.so.2: cannot open shared object file:
hostmpidebug="100"
hostmpimic="1"
#hostmpidevice="ofa-v2-mlx4_0-1s"
#hostmpidaplproviderlist="ofa-v2-mlx4_0-1,ofa-v2-scif0,ofa-v2-mic0,ofa-v2-ib0,ofa-v2-mlx4_0-1s"


envhost="-genv I_MPI_MIC_ENABLE $hostmpimicenable \
         -genv I_MPI_MIC 1 \
         -genv I_MPI_DEBUG $hostmpidebug "
        #  -env I_MPI_MIC $hostmpimic \
        #-env I_MPI_FABRICS $hostmpifabric \
         #-genv I_MPI_DAPL_PROVIDER_LIST $hostmpidaplproviderlist \
         #-genv I_MPI_FABRICS $hostmpifabric \
         #-genv I_MPI_DEVICE $hostmpidevice"

envphi=" $envhost \
         -genv LD_LIBRARY_PATH $MIC_LD_LIBRARY_PATH \
         -genv I_MPI_PIN_MODE $phimpipinmode \
         -genv I_MPI_POSTFIX $phimpipostfix "

if [ ! -d $phimpiprefix ]; then
  mkdir $phimpiprefix
fi

#$mpf90 -fc=ifort -mmic hello_mpi.f90 -o $phimpiprefix/hello.mic
mpiifort -mmic -g -traceback -C hello_mpi.f90 -o $top/hello.mic

#cp -v $top/hello.mic  $top/$phimpiprefix/hello.mic

chmod -v 755 $top/hello 
chmod -v 755 $top/hello.mic

echo "+-----------------------+"
echo "| Running on 1-host     |"
echo  "------------------------"

#export I_MPI_FABRICS=dapl
#export I_MPI_FABRICS=ofa
#export I_MPI_OFA_ADAPTER_NAME=mlx4_0
#export I_MPI_FABRICS=tcp
#export I_MPI_CHECK_DAPL_PROVIDER_COMPATIBILITY=yes

echo "Host"
$mpiexechydra  -n 1 -host smic010 $top/hello 
echo "Phi"
$mpiexechydra  $envphi -n 1 -host smic010p-mic0  $top/hello.mic
echo "Host+Phi"
$mpiexechydra  -n 1 -host smic010 $top/hello \
     : $envphi -n 1 -host smic010p-mic0  $top/hello.mic

exit

echo "+-----------------------+"
echo "| Running on 2-hosts    |"
echo  "------------------------"

echo "2-Similar-Hosts"
$mpiexechydra -n 1 -host smic003 ./hello : -n 1 -host smic001  ./hello 

echo "2-Different-Hosts"
eadd="-env I_MPI_FABRICS ofa -env I_MPI_OFA_ADAPTER_NAME mlx4_0"
$mpiexechydra $eadd -n 1 -host smic004 ./hello : $eadd -n 1 -host smic001  ./hello

echo "2-Similar-Hosts+phis"
#eadd1="-env I_MPI_FABRICS dapl,tcp"
$mpiexechydra -n 1 -host smic003  ./hello \
   :          -n 1 -host smic001  ./hello \
   : $envphi  -n 1 -host smic001p-mic0 ./hello.mic \
   : $envphi  -n 1 -host smic001p-mic1 ./hello.mic \
   : $envphi  -n 1 -host smic003p-mic0 ./hello.mic \
   : $envphi  -n 1 -host smic003p-mic1 ./hello.mic 

echo " "
echo "2-Different-Hosts+phis"
eadd1=" -env I_MPI_OFA_ADAPTER_NAME mlx4_0"
eadd2="-genv I_MPI_DEVICE rdssm -genv I_MPI_FALLBACK_DEVICE 0 -genv I_MPI_FABRICS shm,tcp,dapl"
mpirun="mpirun -r ssh -rr "
$mpirun  -n 1 -host smic001  ./hello \
   :          -n 1 -host smic004  ./hello \
   : $envphi  -n 1 -host smic001p-mic0 ./hello.mic \
   : $envphi  -n 1 -host smic001p-mic1 ./hello.mic \
   : $envphi  -n 1 -host smic003p-mic0 ./hello.mic \
   : $envphi  -n 1 -host smic003p-mic1 ./hello.mic \


exit
#$mpiexechydra -env I_MPI_OFA_ADAPTER_NAME mlx4_0 -perhost 1 -host smic002,smic001  ./hello 

#$mpiexechydra -n 1 $envphi -host smic001p-mic0 ./hello
#exit
sleep 2

echo "+--------------------------+"
echo "| Running on 1-host+2-phis |"
echo  "---------------------------"

echo "Run over scif"
#export I_MPI_FABRICS=dapl
#export I_MPI_OFA_ADAPTER_NAME=scif0
#export I_MPI_FABRICS=ofa
#export I_MPI_OFA_ADAPTER_NAME=mlx4_0

#comm="$mpiexechydra -n 2 -host smic001,smic002 ./hello : $envphi -n 2 -host smic001p-mic0 ./hello"
comm="$mpiexechydra -n 2 -host smic001 ./hello \
          : $envphi -n 2 -host smic001p-mic0 ./hello  \
          : $envphi -n 2 -host smic001p-mic1 ./hello "

#                    -n 2 -host smic002 ./hello : $envphi -n 2 -host smic002p-mic1,smic002p-mic0 ./hello "
echo $comm
$comm
sleep 3

echo "+--------------------------+"
echo "| Running on 2-host+4-phis |"
echo  "---------------------------"


export I_MPI_MIC=1
export I_MPI_MIC_ENABLE="enable"
comm="$mpiexechydra -n 2 -host smic001,smic003 ./hello \
          : $envphi -n 1 -host smic001p-mic0 ./hello.mic  \
          : $envphi -n 1 -host smic001p-mic1 ./hello.mic \
                    -n 1 -host smic003 ./hello \
          : $envphi -n 1 -host smic003p-mic0 ./hello.mic  \
          : $envphi -n 1 -host smic003p-mic1 ./hello.mic "


#                    -n 2 -host smic002 ./hello : $envphi -n 2 -host smic002p-mic1,smic002p-mic0 ./hello "
echo $comm
$comm
sleep 3
exit
