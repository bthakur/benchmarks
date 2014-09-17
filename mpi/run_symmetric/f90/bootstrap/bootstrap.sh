#!/bin/sh

cmd=ssh

#echo "+------------------+"
#echo "| Setup compilers  |"
#echo "+------------------+"
#HostMpi=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/intel64/bin
#PhiMpi=/usr/local/compilers/Intel/cluster_studio_xe_2013.1.046/impi/4.1.3.048/mic/bin


export HostMpi=$impi_top/intel64/bin
export PhiMpi=$impi_top/mic/bin




for arg in $@
do
#echo "Processing argument $arg"
{
if [ "$arg" != "${arg/pmi_proxy/}" ]
then
#echo "Processing argument $arg node ${node}"
if [[ `echo ${node} | grep "\-mic" ` ]]; then
  #echo "this is mic"
  mic_cmd="${cmd} env PATH="${PhiMpi}:\${PATH}" env LD_LIBRARY_PATH="$MIC_LD_LIBRARY_PATH""
  cmd=${mic_cmd/intel64/mic}
  arg=${arg/intel64/mic}
else
  #echo "this is host"
  cmd="${cmd} env PATH="${HostMpi}:\${PATH}""
fi
fi
node=${arg}
cmd="${cmd} ${arg}"
#mic_cmd="${cmd} ${arg}"
}
done
#echo Node ${node}
#echo "new cmd = $cmd"

exec ${cmd}

