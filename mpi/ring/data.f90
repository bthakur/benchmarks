module data
  
  use set_precision
  use mpi_stuff
  use time

  implicit none

! Variables: Indices
    integer(kind=i18),save :: n, nb
    integer(kind=i18)      :: irank
    integer(kind=i18), allocatable,save :: local_ini(:), &
                                     local_fin(:),local_siz(:), &
                                nbr_rgt(:), nbr_lft(:)

! Variables: Arrays
    real(kind=sp), allocatable :: u(:), ucopy(:)

contains

! +--------------
! | Define neighbor
! +--------------
subroutine define_neighbors
  implicit none
  integer irnk
  allocate(nbr_lft(0:procs-1), nbr_rgt(0:procs-1))
  do irnk=0, procs-1
    nbr_lft(irnk)= mod(irnk-1+procs,procs)
    nbr_rgt(irnk)= mod(irnk+1+procs,procs)
  end do
  if (rank==0) then
    write(*,*)'Neighbors:'
    do irnk=0, procs-1
      write(6,'(a6,i4,a2,i4,a2,i4)')"Send", &
        nbr_lft(irnk),"->",irnk,"->",nbr_rgt(irnk)
    end do
    write(6,*)'-----'
 end if
end subroutine define_neighbors
!
! +--------------
! | Partition data
! +--------------
subroutine partition_data
  implicit none
  integer seed_size, seed
  ! Check if not enough data
    if (procs>n) then
      if (rank==0) write(6,*)"Small vector size",n, "Too many procs", procs
        Call MPI_Finalize(mpierr)
      stop
    end if
  ! Block Size that will work for all
    nb= (n+procs-1)/procs
    !
    allocate(local_ini(0:procs-1), &
             local_fin(0:procs-1), &
             local_siz(0:procs-1)  )
    local_siz=0
    local_ini=1
    local_fin=nb
  ! Header
    if (rank==0) then
      write(6,*)"Vector Partions:"
      write(6,'(a6,4a8)')"Rank" ,"Initial","Final", "Size", "Block"
    end if
  ! Distribute vector across ranks
    do irank=0,procs-1
      local_siz(irank)=(n+procs-irank-1)/procs
      if (irank.ne.0) &
        local_ini(irank)=local_fin(irank-1)+1
        local_fin(irank)=local_ini(irank)+local_siz(irank) -1
      if (rank==0) &
        write(6,'(i6,4i8)')irank, local_ini(irank), &
                local_fin(irank), local_siz(irank), nb
    end do
end subroutine partition_data

! +--------------
! | Allocate data
! +--------------
subroutine alloc_data
  implicit none
  integer seed, i, ilocal
  real x
  ! Allocate real data to actual size
    allocate(u(local_siz(rank)))
    allocate(ucopy(nb))
    u=0.0
    ucopy=0.0
 ! Random stuff
    call random_seed()
    call random_number(x)
    seed=1000*rank*x
    call random_seed(seed)
  ! Seed based on Rank
    do i=1,local_siz(rank)
      call random_number(x)
      u(i)=x
    end do
    if (rank==0) &
      write(6,*)'Initial values:'
    !
    call MPI_Barrier(MPI_COMM_WORLD, mpierr)
  ! Seed based on interleaving: Not using but good
    if (.false.) then
    do i=1,n
      ilocal=i-local_ini(rank)+1
      call random_number(x)
      if ((i.ge.local_ini(rank)) .and. (i.le.local_fin(rank))) then
        u(ilocal)=x
        !write(6,*)i,rank,x,u(ilocal)
      end if
    end do
    end if
    !

    write(6,'(a8,i4,4f6.3,a4,4f6.3)')"u(:)", rank, &
                u(1:min(4,local_siz(rank))), '...',&
                        u(local_siz(rank))
    !write(6,'(a12,i4,10f6.3)')"Firt few uc", rank, ucopy(1:min(10,local_siz(rank)))
    call MPI_Barrier(MPI_COMM_WORLD, mpierr)

    !stop
end subroutine alloc_data

subroutine clear_data
  implicit none
! Free memory
  if (allocated(local_ini)) deallocate(local_ini, local_fin, local_siz)
  if (allocated(nbr_lft)) deallocate(nbr_lft,nbr_rgt)
  if (allocated(u)) deallocate(ucopy)
  
end subroutine clear_data

subroutine iterate
  implicit none
  ! Iterate
   
end subroutine iterate

subroutine shift_once
  implicit none

end subroutine shift_once
end module data
