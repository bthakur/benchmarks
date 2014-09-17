program hello_mpi

  use mpi

  implicit none

  integer :: rank,procs,mpierr,plen
  character(len=MPI_MAX_PROCESSOR_NAME) :: pname
  call MPI_Init(mpierr)

  Call MPI_Get_Processor_Name(pname, plen,mpierr)
  call MPI_Comm_Size(MPI_COMM_WORLD,procs,mpierr)
  Call MPI_Comm_Rank(MPI_COMM_WORLD,rank, mpierr)

  print *, rank, trim(pname)

  call MPI_Finalize(mpierr)

end
