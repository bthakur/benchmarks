! Reduction Bandwidth Test
! Bhupender Thakur 2014

program reduction_mpi

  use mpi

  implicit none
  real, allocatable :: ra(:), rb(:), rc(:)
  integer :: i, j, k, l
  real(kind=4) :: bytes
  real(kind=8) :: t_0, t_1, bw
  character(len=10) :: sizetype(3), outcome

  integer :: rank,procs,mpierr,plen
  character(len=MPI_MAX_PROCESSOR_NAME) :: pname
  integer ::  win


  sizetype(1)='onlybytes'
  sizetype(2)='kilobytes'
  sizetype(3)='megabytes'

  Call MPI_Init(mpierr)

  Call MPI_Get_Processor_Name(pname, plen,mpierr)
  call MPI_Comm_Size(MPI_COMM_WORLD,procs,mpierr)
  Call MPI_Comm_Rank(MPI_COMM_WORLD,rank, mpierr)

  print *, rank, trim(pname)
  Call system('hostname')
  ! Loop over array size
  if (rank==0) &        
  write(6,'(6a12)') &
  'Reduction', 'Size', 'Units', 'Check', 'WallTime', 'BW(Gbps)'
  do i = 0, 28
    ! Allocate
    j=2**i
    bytes=4.0*float(j)
    if (j/1024 == 0) then
      k=1
    elseif(j/(1024*1024) == 0) then
      k=2
    elseif(j/(1024*1024*1024) == 0) then
      k=3
    end if
    !print *, j/1024
    allocate(ra(j), rb(j))
    ra=1.0; rb=0.0
    !Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    t_0= MPI_Wtime()
    !CALL MPI---Put ( array1,1000 , MPI_REAL, to, offset1 , 1000 , MPI---REAL , 
    !window , error ) 
    !CALL MPI---Get ( array2,1000 , MPI_REAL, from, offset2 , 1000 , MPI---REAL , 
    !window , error ) 
    Call MPI_Put(ra, j, MPI_REAL, 0, 0, j, MPI_REAL, win, mpierr )
    t_1= MPI_Wtime()
    bw= (real(j)*8.d0*4.d0)/((t_1-t_0)*1000000000.d0)
    ! Deallocate
    if (allocated(ra)) then
      if (rank==0) then 
        if ( nint(rb(j))==procs ) then
          outcome="Success"
        else
          outcome="Failure"
          stop
        end if
          
        write(6,'(a12,i12,2a12,f12.6,f12.6)') &
        'Reduction', nint(bytes/(1024**(k-1))),sizetype(k), outcome, t_1-t_0, bw
        !print *, rb(j)
      end if
      deallocate(ra, rb)
    end if

  end do ! i
  call MPI_Finalize(mpierr)

end
