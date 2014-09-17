#source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/bin/compilervars.sh intel64
source /usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/vtune_amplifier_xe_2013/amplxe-vars.sh
export LD_LIBRARY_PATH=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/lib/mic

echo '# +-------------------------+'
echo '# | Run natively on the phi |'
echo '# +-------------------------+'
echo '  '
./matrix.mic
