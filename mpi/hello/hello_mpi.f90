program hello_mpi

  use mpi
  character*10 name

! Init MPI
  call MPI_Init(ierr)

! Get Rank Size
  call MPI_COMM_Rank(MPI_COMM_WORLD, nrank, ierr)
  call MPI_COMM_Size(MPI_COMM_WORLD, nproc, ierr)

! Print Date
  if (nrank==0) then
    write(*,*)'System date:'
    call system('date')
  end if

! Print rank
  !call MPI_Barrier(comm, ierr)
  call MPI_Get_processor_name(name, nlen, ierr)
  write(*,*)" I am",nrank,"of",nproc,"on ", name
  !
! Finalize
    call MPI_Finalize(ierr)

end
