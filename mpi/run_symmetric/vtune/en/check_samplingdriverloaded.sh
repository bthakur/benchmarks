#!/bin/bash -x

host=`uname -n`

cluster=`echo $host|tr -d [0-9]`


CLUSTERSTUDIO_TOP="/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046"
COMPOSER_VER="composer_xe_2013_sp1.2.144"
VTUNE_VER="vtune_amplifier_xe_2013"
export VTUNE_TOP=$CLUSTERSTUDIO_TOP/$VTUNE_VER

source $CLUSTERSTUDIO_TOP/$VTUNE_VER/amplxe-vars.sh  x86-64
source $CLUSTERSTUDIO_TOP/$COMPOSER_VER/bin/compilervars.sh intel64

#############

case "$cluster" in
  'smic')
   phi0=${host}p-mic0
   ;;
   'shelob')
   phi0=mic0
   ;;
esac

#############


echo " -------- "
echo " Check if Sampling driver is loaded on host"
$VTUNE_TOP/sepdk/src/insmod-sep3 -q
echo " "

echo " -------- "
echo "Check if Sampling driver is loaded on Phi"
ssh $phi0 $VTUNE_TOP/sepdk/src/insmod-sep3 -q
echo " "

