FC    = ifort
MPIFC = mpiifort

FFLAGS = -g -traceback -check all

all:    hello hello.mic reduce reduce.mic
host:   hello reduce
mic:    hello.mic reduce.mic

hello:
	$(MPIFC) -fc=$(FC) src/hello_mpi.f90 -o bin/$@

hello.mic:
	$(MPIFC) -fc=$(FC) -mmic src/hello_mpi.f90 -o bin/$@

reduce:
	$(MPIFC) -fc=$(FC) src/reduce_mpi.f90 -o bin/$@

reduce.mic:
	$(MPIFC) -fc=$(FC) -mmic src/reduce_mpi.f90 -o bin/$@

clean:
	rm bin/hello bin/hello.mic bin/reduce bin/reduce.mic
