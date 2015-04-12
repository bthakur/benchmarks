module set_precision

    implicit none
    integer, parameter :: i18=selected_int_kind(18);
    integer, parameter :: sp =selected_real_kind(6, 37)
    integer, parameter :: dp =selected_real_kind(15, 307)
end module set_precision

  module time

    use set_precision
    implicit none
    !
    real(kind=dp)      :: r_mem
    integer(kind=i18)  :: j_mem, i_mem

    integer, save :: t_m, t_n, t_o
    integer, save :: val0(8), val1(8), val2(8)   
    real, save :: etime1(2), etime2(2), tresult
    real, save :: t0, t1, t2, t3 ! t4, tcpu1, tcpu2, twall1, twall2


    real, save :: tloop_beg_dat, tloop_beg_mul, tloop_beg_snd, tloop_beg_cpy, &
                  tloop_beg_alp, tloop_beg_bet, tloop_beg_swp, tloop_beg_mv

    real, save :: tloop_end_dat, tloop_end_mul, tloop_end_snd, tloop_end_cpy, &
                  tloop_end_alp, tloop_end_bet, tloop_end_swp, tloop_end_mv

    real, save :: tloop_dat, tloop_mul, tloop_snd, tloop_cpy, &
                  tloop_cpu, tloop_alp, tloop_bet, tloop_swp, &
                  tloop_mv
  contains

  real function time_dt()
    integer :: val(8)
    call date_and_time(VALUES=val)
    time_dt=float(val(2)+val(3)*3600*24+val(5)*3600+val(6)*60+val(7))&
       + val(8)*.001
  end function

  end module time

! +------------------+
! | MPI declarations |
! +------------------+
  module mpi_stuff

    use omp_lib

! ATTN: Using module conflicts in F90 bindings
    !use mpi
    implicit none
    INCLUDE 'mpif.h'

! Mpi variables
    integer mpierr, rank, nproc, tag, sendreq, recvreq, req(2)
    integer status(MPI_STATUS_SIZE)
! Openmp variables
    !integer OMP_GET_THREAD_NUM, OMP_GET_NUM_THREADS
    integer tid !, OMP_GET_THREAD_NUM
    integer ntd !, OMP_GET_NUM_PROCS, OMP_get_num_threads
    integer maxthds !  omp_get_max_threads
    integer iter

  end module mpi_stuff

! +------------------+
! | Lapack Stuff     |
! +------------------+
  module lapack_stuff
    use set_precision
    implicit none
    integer i,j,n, info
    integer, allocatable :: iwork(:)

    real(kind=sp), allocatable :: smat(:,:)
    real(kind=sp), allocatable :: swork(:), sw(:)

    real(kind=dp), allocatable :: dmat(:,:)
    real(kind=dp), allocatable :: dwork(:), dw(:)

    contains

  !interface s_dstev
  subroutine s_stev(job,trd_dg, trd_sdg, ndg)
    implicit none
    real, dimension(:), intent(inout) :: trd_dg, trd_sdg
    !integer(kind=i18), intent(in)     :: ndg
    integer, intent(in)        :: ndg
    character*1, intent(in)    :: job

    real, allocatable          :: z(:,:), work(:)
    integer                    :: ldz
    integer                    :: info

    !n=(ubound(trd_dg)-lbound(trd_dg)) +1

    ldz=ndg
    allocate(z(ldz,ndg), work(2*ndg-2))
    z=0.0
    info=100
    work=0.0
    !write(*,*) job,ndg
    !write(*,*) trd_dg, trd_sdg 
    !write(*,*)z, ldz, work, info
    !stop
    !if (job.eq.'N') then

    !SUBROUTINE DSTEV( JOBZ, N, D, E, Z, LDZ, WORK, INFO )
     call SSTEV( job, ndg, trd_dg, trd_sdg, z, ldz, work, info )
    !call DSTEV( job, ndg, trd_dg, trd_sdg, info )
    !else if (job.eq.'V') then
    !else
    !end if
    
! +--------------------------------------------+
! ! Print out results                          |
! +--------------------------------------------+
    !write(*,*)"Eigenvalues: In increasing order magnitude"
    !do j=1,n
    !  write(*,'(12f6.2)') w(j)
    !end do
    !write(*,*)"             "
! +--------------------------------------------+
! ! Deallocate matrices                        |
! +--------------------------------------------+

    deallocate(z,work)
  end subroutine 
  !end interface

  subroutine s_syev(job,part,ndim, syev_mat)
    implicit none
    real, dimension(:), intent(inout) :: syev_mat
    integer, intent(in)        :: ndim
    character*1, intent(in)    :: job, part

    real, allocatable          :: w(:), work(:)
    integer, allocatable       :: iwork(:)

    integer                    :: info

    !n=(ubound(trd_dg)-lbound(trd_dg)) +1

    allocate(work(2*ndim-2),w(2*ndim-2), iwork(2*ndim-2))
    info=100
    w=0.0
    work=0.0
    iwork=0
    
    !write(*,*) job,ndg
    !write(*,*) trd_dg, trd_sdg 
    !write(*,*)z, ldz, work, info
    !stop
    !if (job.eq.'N') then

    !CALL DSYEVD('V','U', n,    mat,     n,   w,work,1000,iwork,1000,info)
    CALL SSYEVD(job, part,ndim, syev_mat,ndim,w,work,1000,iwork,1000,info)

    !SUBROUTINE DSTEV( JOBZ, N, D, E, Z, LDZ, WORK, INFO )
    ! call SSTEV( job, ndg, trd_dg, trd_sdg, z, ldz, work, info )
    !call DSTEV( job, ndg, trd_dg, trd_sdg, info )
    !else if (job.eq.'V') then
    !else
    !end if
    
! +--------------------------------------------+
! ! Print out results                          |
! +--------------------------------------------+
    !write(*,*)"Eigenvalues: In increasing order magnitude"
    !do j=1,n
    !  write(*,'(12f6.2)') w(j)
    !end do
    !write(*,*)"             "
! +--------------------------------------------+
! ! Deallocate matrices                        |
! +--------------------------------------------+

    deallocate(w,work,iwork)
  end subroutine 
  !end interface

  end module lapack_stuff
