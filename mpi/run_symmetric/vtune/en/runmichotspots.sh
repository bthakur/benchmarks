source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh x86-64
export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/intel64:/opt/intel/mic/coi/host-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/ipp/../compiler/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/ipp/lib/intel64:/opt/intel/mic/coi/host-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mkl/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/tbb/lib/intel64/gcc4.4:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/intel64:/opt/intel/mic/coi/host-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/ipp/../compiler/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/ipp/lib/intel64:/opt/intel/mic/coi/host-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mkl/lib/intel64:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/tbb/lib/intel64/gcc4.4:/usr/local/compilers/Intel/composer_xe_2013.0.079/compiler/lib/intel64:/usr/local/compilers/Intel/composer_xe_2013.0.079/mkl/lib/intel64:/usr/local/packages/openmpi/1.6.2/Intel-13.0.0/lib:/usr/local/packages/openmpi/1.6.2/Intel-13.0.0/lib64

#echo '# +-------------------------+'
#echo '# | Run natively on the phi |'
#echo '# +-------------------------+'
#echo '  '
./matrix.mic