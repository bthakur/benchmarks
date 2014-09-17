#!/bin/bash

source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh  x86-64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64

export optsphi="-c knc-hotspots"

amplxe-cl $optsphi -- ssh mic0 ls

amplxe-cl $optsphi -- ssh mic0 /home/bthakur/vtune/en/C++/matrix/linux/matrix.mic
