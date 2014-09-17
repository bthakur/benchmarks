#source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh
export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/lib/mic

echo '# +---------------------------+'
echo '# | Run executable on the phi |'
echo '# +---------------------------+'
echo '  '
#./matrix.mic

echo '# +---------------------------------------------+'
echo '# | Run advanced hotspots on the phi executable |'
echo '# +---------------------------------------------+'
echo '  '

#export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/lib/mic:/opt/intel/mic/coi/device-linux-release/lib:/opt/intel/mic/myo/lib:/opt/intel/mic/coi/device-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mkl/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/tbb/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mpirt/lib/mic:/opt/intel/mic/coi/device-linux-release/lib:/opt/intel/mic/myo/lib:/opt/intel/mic/coi/device-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/compiler/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/mkl/lib/mic:/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/composer_xe_2013_sp1.2.144/tbb/lib/mic:/usr/local/compilers/Intel/composer_xe_2013.0.079/compiler/lib/mic:/opt/intel/mic/coi/device-linux-release/lib:/opt/intel/mic/myo/lib:/usr/local/compilers/Intel/composer_xe_2013.0.079/mkl/lib/mic
scp /project/bthakur/benchmarks_builds/vtune/en/C++/matrix/linux/matrix.mic mic0: 
amplxe-cl  -collect knc-hotspots  -- ssh mic0 ./matrix.mic
exit
