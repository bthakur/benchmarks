##******************************************************************************
##  Copyright(C) 2001-2011 Intel Corporation. All Rights Reserved.
##  
##  The source code, information  and  material ("Material") contained herein is
##  owned  by Intel Corporation or its suppliers or licensors, and title to such
##  Material remains  with Intel Corporation  or its suppliers or licensors. The
##  Material  contains proprietary information  of  Intel or  its  suppliers and
##  licensors. The  Material is protected by worldwide copyright laws and treaty
##  provisions. No  part  of  the  Material  may  be  used,  copied, reproduced,
##  modified, published, uploaded, posted, transmitted, distributed or disclosed
##  in any way  without Intel's  prior  express written  permission. No  license
##  under  any patent, copyright  or  other intellectual property rights  in the
##  Material  is  granted  to  or  conferred  upon  you,  either  expressly,  by
##  implication, inducement,  estoppel or  otherwise.  Any  license  under  such
##  intellectual  property  rights must  be express  and  approved  by  Intel in
##  writing.
##  
##  *Third Party trademarks are the property of their respective owners.
##  
##  Unless otherwise  agreed  by Intel  in writing, you may not remove  or alter
##  this  notice or  any other notice embedded  in Materials by Intel or Intel's
##  suppliers or licensors in any way.
##
##******************************************************************************
##  Content:
##      NQueens Fortran sample
##******************************************************************************
##
## To compile with the Intel(R) Fortran Compiler for Linux*:
##
## source <path_to_compiler_bin>/compilervars.sh or compilervars.csh
##
## > make
##

SHELL = /bin/sh


FC = ifort
FFLAG = -O3 -g -debug inline-debug-info
OMP_LIB = openmp

SRCDIR = ../src

PROGS = nqueens_parallel nqueens_serial

all:: $(PROGS)

nqueens_parallel: $(SRCDIR)/nqueens_parallel.f90
	$(FC) $(FFLAG) -$(OMP_LIB) $< -o $@


nqueens_serial: $(SRCDIR)/nqueens_serial.f90
	$(FC) $(FFLAG) -$(OMP_LIB) $< -o $@


clean:
	- rm -f core 
	- rm -f $(PROGS) *.o

