#!/bin/bash

# +-----------------------+
# | Source compiler stuff |
# +-----------------------+

source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh x86_64

echo '# +-----------------------------------+'
echo '# | Run advanced hotspots on the host |'
echo '# +-----------------------------------+'

#if false; then
  exe=$(pwd)/C++/matrix/linux/matrix.gcc
  exephi=$(pwd)/C++/matrix/linux/matrix.mic
  #opts="-collect-with  runsa -knob event-config=ICACHE.MISSES:sa=5000 -knob enable-stack-collection=true"
  opts=" -c advanced-hotspots "
  #amplxe-cl $opts -- $exe
#fi
#exit

echo '# +----------------------------------+'
echo '# | Run advanced hotspots on the phi |'
echo '# | copy/run it natively             |'
echo '# +----------------------------------+'
sleep 3

exe=$(pwd)/C++/matrix/linux/matrix.mic
opts=" -c advanced-hotspots "
optsphi=" -collect knc-hotspots "
#-collect-with  runsa -knob event-config=ICACHE.MISSES:sa=5000 -knob enable-stack-collection=true"
cat << EOF > runmicnative.sh
#source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh
export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/lib/mic

echo '# +-------------------------+'
echo '# | Run natively on the phi |'
echo '# +-------------------------+'
echo '  '
./matrix.mic
EOF

#export LD_LIBRARY_PATH=$MIC_LD_LIBRARY_PATH
#scp $exephi mic0: 
#amplxe-cl $optsphi -- ssh mic0 ./matrix.mic
#exit

# Copy to themic and run there
  scp runmicnative.sh mic0:
  scp $exe mic0:

  echo "Copied: now running"
  sleep 2

# ssh mic0 ./matrix.mic
  #ssh mic0 "sh runmicnative.sh"


echo '# +---------------------------------------------+'
echo '# | Run advanced hotspots on the phi executable |'
echo '# +---------------------------------------------+'
echo '  '
cat << EOF > runmichotspots.sh
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh x86-64
export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/lib/mic:$LD_LIBRARY_PATH

#echo '# +-------------------------+'
#echo '# | Run natively on the phi |'
#echo '# +-------------------------+'
#echo '  '
./matrix.mic
EOF

  scp runmichotspots.sh mic0:


optsphi=" -collect knc-hotspots "
amplxe-cl $optsphi -- ssh mic0 env LD_LIBRARY_PATH=$MIC_LD_LIBRARY_PATH ./matrix.mic
exit
amplxe-cl $optsphi -- ssh mic0 'sh -x runmichotspots.sh'

