! +
!   Implementation of Cannon's algorithm
!   Assuming: square matrix, nproc*nproc processors
!   Bhupender Thakur hpc@lsu: 05/01/2013
! +

! +----------------------------------+
! ! Modules for variable declarations
! +----------------------------------+
  ! Set precision
    module set_precision
    !
    implicit none
    integer, parameter :: i18=selected_int_kind(18);
    integer, parameter :: sp =selected_real_kind(6, 37)
    integer, parameter :: dp =selected_real_kind(15, 307)
    !
    end module set_precision

  ! MPI declarations
    module mpi_stuff
    !
    implicit none
    include 'mpif.h'
    integer :: rank,nproc, nproc_square, mpierr, tag, req(4)
    integer :: stats(MPI_STATUS_SIZE,2)
    !
    end module mpi_stuff
  
  ! Matrix definitions
    module matrix_elements
    !
    use set_precision
    implicit none
    !
    integer(kind=i18) :: mrow, ncol
    integer(kind=i18), allocatable :: row_i(:), row_f(:), col_i(:), col_f(:)
    real, allocatable :: a(:,:), b(:,:),c(:,:),a_copy(:,:), b_copy(:,:)
    integer :: irank, irow, jcol, ir, il
    integer :: row_block, col_block, max_block, k, iter
    integer, allocatable :: row_of_rank(:),   col_of_rank(:), &
                            neighbor_top(:),  neighbor_left(:), &
                            neighbor_down(:), neighbor_right(:), &
                            rowcol_to_rank(:,:) 
    end module matrix_elements

! +----------------------------------+
! ! Main program
! +----------------------------------+

program matmul1

  use set_precision
  use mpi_stuff
  use matrix_elements

  implicit none

! +----------------------------------+
! | Define sizes
! +----------------------------------+

  mrow=29
  ncol=mrow

! +----------------------------------+
! | Initialize mpi
! +----------------------------------+

  Call MPI_Init(mpierr)

! +----------------------------------+
! | Rank and Size
! +----------------------------------+

  Call MPI_Comm_Size(MPI_COMM_WORLD, nproc_square, mpierr)
  Call MPI_Comm_Rank(MPI_COMM_WORLD, rank, mpierr)

  nproc=nint(sqrt(float(nproc_square)))

! +----------------------------------+
! | Check for square processors
! +----------------------------------+
  ! Todo
! +----------------------------------+
! | Define rank partition and neighbors, assume column major ranking
! +----------------------------------+
  ! [ 0 | 3 | 6 ]
  ! [ 1 | 4 | 7 ]
  ! [ 2 | 5 | 8 ]

  allocate( row_of_rank    (0:nproc_square-1),   &
            col_of_rank    (0:nproc_square-1),   &
            neighbor_top   (0:nproc_square-1),   &
            neighbor_down  (0:nproc_square-1),   &
            neighbor_left  (0:nproc_square-1),   &
            neighbor_right (0:nproc_square-1),   &
            rowcol_to_rank (0:nproc-1, 0:nproc-1))

  do irank=0, nproc_square-1
  ! column major ordering of ranks
    row_of_rank(irank) = mod(irank,nproc)
    col_of_rank(irank) = irank/nproc
  ! top/down neighbor
    neighbor_top(irank) = irank -1
    neighbor_down(irank) = irank +1
    if (row_of_rank(irank)==0) neighbor_top(irank)=irank+nproc-1
    if (row_of_rank(irank)==(nproc-1)) neighbor_down(irank)=irank-nproc+1
  ! left/right neighbor
    neighbor_left(irank) = irank -nproc
    neighbor_right(irank) = irank +nproc
    if (col_of_rank(irank)==0) neighbor_left(irank)=irank+(nproc-1)*nproc
    if (col_of_rank(irank)==(nproc-1)) neighbor_right(irank)=mod(irank,nproc)
  ! reverse mapping to rank
    rowcol_to_rank(row_of_rank(irank), col_of_rank(irank))= irank
  end do

  !if (.false.) then
  if (rank==0) then
   write(*,*)'+ Verify some neighbors +' 
   do irank=0, nproc_square-1,3!nproc_square-1
      write(*,*)"--------------"
      write(*,'(4x,i4)') neighbor_top(irank)
      write(*,'(3i4)')   neighbor_left(irank), irank,neighbor_right(irank)
      write(*,'(4x,i4)') neighbor_down(irank)
    end do
  end if
  !end if

  !stop

! +----------------------------------+
! | Initialize row and col
! +----------------------------------+

! Row partitioning
    max_block = (mrow+nproc)/nproc
    row_block = max_block
    col_block = max_block

    !write(*,'(a6,6i6)')'rank', rank,mrow,mrow+1,nproc,max_block

    allocate(row_i(0:nproc_square-1), row_f(0:nproc_square-1))
    allocate(col_i(0:nproc_square-1), col_f(0:nproc_square-1))
    row_i=-1; col_i=-1
    row_f=-1; col_f=-1

    if (rank==0) then
       write(*,*)'+ Verify partitions +'
       write(*,'(3a5,a2,2a8,a2,2a8)')'rank', 'col', 'row', ':', &
                            'row_i', 'row_f',':','col_i', 'col_f'
    end if

    do irank=0,nproc_square-1
       irow=row_of_rank(irank)
       jcol=col_of_rank(irank)
       ! row_i, row_f
          row_i(irank)= irow*max_block
          row_f(irank)= row_i(irank)+max_block-1
          !row_i(irow) = min(mrow, row_i(irow-1)+max_block)
          !row_f(irow) = min(mrow, row_f(irow-1)+max_block)
       ! col_i, col_f
          col_i(irank)= jcol*max_block
          col_f(irank)= col_i(irank)+max_block-1
          !col_i(jcol) = min(ncol, col_i(irow-1)+max_block)
          !col_f(jcol) = min(ncol, col_f(irow-1)+max_block)
        if (rank==0) then

          !write(*,'(3a5,a2,2a8,a2,2a8)')'rank', 'col', 'row', ':', &
          !                              'row_i', 'row_f',':','col_i', 'col_f'
          write(*,'(3i5,a2,2i8,a2,2i8)')irank,  jcol, irow, ":", &
                                        row_i(irank), row_f(irank),':', &
                                        col_i(irank), col_f(irank)
          if (irow==(nproc-1)) write(*,*)'....................'
        end if

    end do

! +----------------------------------+
! | Allocate A/B
! +----------------------------------+
  !
  allocate(a(0:max_block-1, 0:max_block-1), &
           b(0:max_block-1, 0:max_block-1), &
           c(0:max_block-1, 0:max_block-1)  )
  !write(*,*)max_block
  allocate(a_copy(0:max_block-1, 0:max_block-1), &
           b_copy(0:max_block-1, 0:max_block-1)  )

  a=0.0;b=0.0;c=0.0

! +---------------
! | Initialize A/B
! +---------------
  !
  ! [ a00 | a01 | a02 ]    [ b00 | b01 | b02 ]    
  ! [ a10 | a11 | a12 ]    [ b10 | b11 | b12 ] <-   ^  
  ! [ a20 | a21 | a22 ]    [ b20 | b21 | b22 ] <-- ^^

  ! Pad with zeros@( row,col > mrow ) ones@( elsewhere )
    do irow=0,max_block-1
      do jcol=0,max_block-1
       ! if irow > mrow, jcol > mrow
        if ( (max_block*(row_of_rank(rank))+irow).gt.mrow .or. &
             (max_block*(col_of_rank(rank))+jcol).gt.mrow ) then
              a(irow,jcol)=0.0
              b(irow,jcol)=0.0
              !write(*,*)rank,max_block*(row_of_rank(rank))+irow, &
              !max_block*(col_of_rank(rank))+jcol
        else
              a(irow,jcol)=1.0
              b(irow,jcol)=2.0
              !write(*,*)rank,irow,jcol
              !write(*,*)rank,max_block*(row_of_rank(rank))+irow, &
              !max_block*(col_of_rank(rank))+jcol
        end if
      end do
    end do

    a_copy=a; b_copy=b

! +----------------------------------+
! | A/B after initial alignment
! +----------------------------------+
  !
  ! Skewed rows for A
  ! [ a00 | a01 | a02 ]   0  0  0    
  ! [ a11 | a12 | a12 ]   <  <  <
  ! [ a22 | a20 | a21 ]  << << <<
  !
  ! A
  ! shift row irow*times to left
    if (row_of_rank(rank).ne.0) then
        ir=rank
        il=rank
    do irow=1, row_of_rank(rank)
        il=neighbor_left(il)
        ir=neighbor_right(ir)
    end do
 
    Call MPI_Irecv(a_copy,max_block**2,MPI_REAL,ir,1000, &
             MPI_COMM_WORLD, req(1), mpierr)
    Call MPI_Isend(a,max_block**2,MPI_REAL,il,1000, &
             MPI_COMM_WORLD, req(2), mpierr)
    !write(*,*)rank,'recv',ir,'send',il, a
    end if

  ! Skewed cols for B
  ! [ b00 | b11 | b22 ]  0  ^ ^^
  ! [ b10 | b21 | b02 ]  0  ^ ^^
  ! [ b20 | b01 | b12 ]  0  ^ ^^
  !
  ! B
  ! shift jcol jcol*times up
    if (col_of_rank(rank).ne.0) then
        ir=rank
        il=rank
    do jcol=1, col_of_rank(rank)
        il=neighbor_top(il)
        ir=neighbor_down(ir)
    end do

    Call MPI_Irecv(b_copy,max_block**2,MPI_REAL,ir,2000, &
             MPI_COMM_WORLD, req(3), mpierr)
    Call MPI_Isend(b,max_block**2,MPI_REAL,il,2000, &
             MPI_COMM_WORLD, req(4), mpierr)

    !Call MPI_Sendrecv(b,max_block**2,MPI_REAL,0,tag+1000, &
    !         b_copy,max_block**2,MPI_REAL,ir,tag+1000,&
    !         MPI_COMM_WORLD, MPI_STATUS_IGNORE, mpierr)

    end if

    Call MPI_WAITALL(4, req, MPI_STATUSES_IGNORE, mpierr);

    if ((row_of_rank(rank).ne.0).or.(col_of_rank(rank).ne.0)) then
       a=a_copy
       b=b_copy
    end if
 
    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)

    !if (rank==4) then
    !write(*,*)'verify'
    !write(*,*)rank, b
    !end if
 
! +----------------------------------+
! | Iterate : Compute and shift
! +----------------------------------+
  !
  !write(*,*)'Send/Recv', &
  !          mod(nproc+rank-1,nproc), ' <-', rank, ' <-',mod(rank+1,nproc)

  do iter=1,nproc

    ! +---------------
    ! | Send/Recv
    ! +---------------

      tag=iter
      a_copy=0; b_copy=0  
      ! Non-blocking Send/Recv
      ! Send a to left neighbor for next iteration
      if (.true.) then
       Isend a of size max_block**2 and type MPI_REAL to neighbor_left(rank),tag+1000,&
           communicator, with request req(1),mpierr 
       Irecv a_copy of size max_block**2 and type MPI_REAL from neighbor_right(rank),tag+1000,&
           communicator, with request req(2),mpierr 
      ! Send b to top neighbor for next iteration
      Isend b of size max_block**2 and type MPI_REALto neighbor_top(rank),tag+2000,&
           communicator with request req(3),mpierr 
      Irecv b_copy of size max_block**2 and type MPI_REAL from neighbor_down(rank),tag+2000,&
           communicator, with request req(4),mpierr 
      end if
      ! Blocking Send/Receive
      if (.false.) then
      Call MPI_Sendrecv( a,max_block**2,MPI_REAL,neighbor_left(rank),tag+1000, &
                          a_copy,max_block**2,MPI_REAL,neighbor_right(rank),tag+1000, &
                          MPI_COMM_WORLD, MPI_STATUS_IGNORE, mpierr)
      Call MPI_Sendrecv( b,max_block**2,MPI_REAL,neighbor_left(rank),tag+2000, &
                          b_copy,max_block**2,MPI_REAL,neighbor_right(rank),tag+2000, &
                          MPI_COMM_WORLD, MPI_STATUS_IGNORE, mpierr)
      end if

      ! +----------------------------------+
      ! | Compute local matrix-multiply c=a*b
      ! +----------------------------------+

      do irow=0,max_block-1
       do jcol=0,max_block-1
        do k=0,max_block-1
           c(irow,jcol) = c(irow,jcol) + a(irow,k)*b(k,jcol)
           !if (rank==0) &
           !write(*,*)iter, irow,jcol,c(irow,jcol)
        end do
       end do
      end do

      ! +----------------------------------+
      ! | Wait for communication to finish
      ! +----------------------------------+

      Call MPI_Waitall ( 4, req, MPI_STATUSES_IGNORE, mpierr )

      ! +----------------------------------+
      ! | Copy back for next computation
      ! +----------------------------------+

      a=a_copy; b=b_copy

      Call MPI_Barrier(MPI_COMM_WORLD, mpierr)

  end do ! iter

  ! +----------------------------------+
  ! | Print partial C on each process
  ! +----------------------------------+

    do irank=0,nproc_square-1
    if (rank==irank) then
      write(*,*)'C after on',rank
      write(*,'(10f8.2)')c(0:min(10,max_block-1),:)
    end if
    call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    end do

! +----------------------------------+
! | Deallocate
! +----------------------------------+

  deallocate(a,b,c)

! +----------------------------------+
! | Finalize
! +----------------------------------+

  Call MPI_Finalize(mpierr)

end
