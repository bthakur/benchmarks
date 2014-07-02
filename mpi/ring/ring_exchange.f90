! Exchange large vector on a ring

program ring_exchange

  use data
  implicit none
  integer i, isize
! Initialize MPI
    Call MPI_Init (mpierr)
    Call MPI_COMM_Size(MPI_COMM_WORLD, procs, mpierr)
    Call MPI_COMM_Rank(MPI_COMM_WORLD, rank,  mpierr)

! Check OpenMP 
  !$omp parallel
    ntd = omp_get_num_threads();
   !write(6,*)"This is proc", rank, "of", procs, ntd
  !$omp end parallel

! Partition Vector sizes
    n = 1024_i18
    call define_neighbors
    !Call MPI_Barrier(MPI_COMM_WORLD,mpierr)
    Call partition_data

! Allocate vectors and fill randomly
    Call alloc_data

! Start iteration
    Call MPI_Barrier(MPI_COMM_WORLD,mpierr)
    ! ---------------------
    ! Cycle fully to send all vectors around
    do i=1,procs
      ! ---------------------
      ! Loop to send from each process to its neighbor
      do irank=0,procs-1
        Call MPI_Barrier(MPI_COMM_WORLD,mpierr)
        isize=local_fin(rank)-local_ini(rank)+1

        ! ---------------------
        ! Recv at rank=right_of_irank
        if (rank==nbr_rgt(irank)) then
           call MPI_Recv( ucopy(1:isize), nb, MPI_REAL, irank, MPI_ANY_TAG, &
                         MPI_COMM_WORLD, status, recvst )
           if (recvst /= MPI_SUCCESS ) then
             write(6,*)'recvng error', rank,"<-",irank, isize   
             stop
           else
             if (print_more) &
               write(6,*)'recvng succs', rank,"<-",irank, isize
           end if
        ! ---------------------
        ! Send from irank=rank
        elseif (rank==irank) then
           call MPI_Send( u(1:isize), nb, MPI_REAL,nbr_rgt(rank), 1000*irank, &
                         MPI_COMM_WORLD, sendst )
           if (sendst /= MPI_SUCCESS ) then
             write(6,*)'sendng error', rank,"->",irank, isize
             stop
           else
             if (print_more) &
               write(6,*)'sendng succs', rank,"->",irank, isize
           end if
           !
        end if
     end do
     ! ---------------------
     ! Every processor has exchanged
     ! ucopy is being copied
     ! Waiting: 
     !---------------
     ! Do computation
     ! v=v+2*u_copy
     ! Move to next part of parallel vector
     ! Safe to copy after computation over
       u=ucopy
       ucopy=0.0
       Call MPI_Barrier(MPI_COMM_WORLD,mpierr)
     ! ---------------------
     ! Every processors have exchanged
     ! ucopy is new u
        if (rank==0) then
          write(6,'(a20,2i4,4f6.3,a4,4f6.3)')"u(0) After exchange",i,rank, &
                u(1:min(4,local_siz(rank))), '...',&
                        u(local_siz(rank))
        end if
        if (rank/=0 .and. print_more) &
          write(6,'(a8,2i4,4f6.3,a4,4f6.3)')"u(:)", i,rank, &
                u(1:min(4,local_siz(rank))), '...',&
                        u(local_siz(rank))

    end do
    !Call MPI_Barrier(MPI_COMM_WORLD,mpierr)
   !stop
! Deallocate
    Call clear_data

! Finalize
    Call MPI_Finalize(mpierr)

end program

