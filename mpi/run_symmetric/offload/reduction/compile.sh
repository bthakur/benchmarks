#!/bin/bash

 icpc -openmp reduction0.cpp -o reduction0

 OFFLOAD_REPORT=2 ./reduction0

 opts="-watch=mic_cmd -offload-option,mic,compiler,-mP2OPT_hlo_pref_indirect_refs=T"
 opts="-offload-option,mic,compiler,"-vec-report2 -opt-report-phase hlo -opt-report=3"

 icpc "$opts" \
      -openmp -watch=mic-cmd \
      reduction0.cpp -o reduction0.1

