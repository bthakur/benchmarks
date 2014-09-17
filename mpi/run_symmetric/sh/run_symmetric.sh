#!/bin/sh

source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/bin64/mpivars.sh

mpiexechydra=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/bin/intel64/mpiexec.hydra 

phimpiprefix="./.MIC/"
phimpipinmode="mpd"
hostmpimicenable="enable"
envphi=" -env LD_LIBRARY_PATH $MIC_LD_LIBRARY_PATH -env I_MPI_PIN_MODE $phimpipinmode -env I_MPI_PREFIX $phimpiprefix "
envhost="env I_MPI_MIC_ENABLE=$hostmpimicenable"

cat << EOF > hello
#!/bin/sh 
echo " "
hostname && env |grep SSH_CONNECTION  && echo is responive !
EOF

if [ ! -d $phimpiprefix ]; then
  mkdir $phimpiprefix
fi

cp -v hello  $phimpiprefix/hello

chmod -v 755 hello 
chmod -v 755 $phimpiprefix/hello

echo "+-----------------------+"
echo "| Running on 2-hosts    |"
echo  "------------------------"

$mpiexechydra -perhost 1 -host smic002,smic001  ./hello 

#$mpiexechydra -n 1 $envphi -host smic001p-mic0 ./hello

sleep 2

echo "+--------------------------+"
echo "| Running on 1-host+2-phis |"
echo  "---------------------------"

export I_MPI_MIC=1
export I_MPI_MIC_ENABLE="enable"
#comm="$mpiexechydra -n 2 -host smic001,smic002 ./hello : $envphi -n 2 -host smic001p-mic0 ./hello"
comm="$mpiexechydra -n 2 -host smic001 ./hello \
          : $envphi -n 2 -host smic001p-mic0 ./hello  \
          : $envphi -n 2 -host smic001p-mic1 ./hello "

#                    -n 2 -host smic002 ./hello : $envphi -n 2 -host smic002p-mic1,smic002p-mic0 ./hello "
echo $comm
$comm
sleep 4

echo "+--------------------------+"
echo "| Running on 2-host+4-phis |"
echo  "---------------------------"

export I_MPI_MIC=1
export I_MPI_MIC_ENABLE="enable"
comm="$mpiexechydra -n 2 -host smic001,smic003 ./hello \
          : $envphi -n 1 -host smic001p-mic0 ./hello  \
          : $envphi -n 1 -host smic001p-mic1 ./hello \
                    -n 1 -host smic003 ./hello \
          : $envphi -n 1 -host smic003p-mic0 ./hello  \
          : $envphi -n 1 -host smic003p-mic1 ./hello "


#                    -n 2 -host smic002 ./hello : $envphi -n 2 -host smic002p-mic1,smic002p-mic0 ./hello "
echo $comm
$comm
sleep 4


#$mpiexechydra -n 1 -host smic001 ./hello $envphi -n 1 -host smic001p-mic0 ./hello


#/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/bin/intel64/mpiexec.hydra  -env LD_LIBRARY_PATH $MIC_LD_LIBRARY_PATH -env I_MPI_PIN_MODE mpd -env I_MPI_PREFIX ./MIC/ -n 1 -host smic001p-mic0 hello


