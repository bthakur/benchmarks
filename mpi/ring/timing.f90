! +------------------+
! | Precision        |
! +------------------+
!
module set_precision

    implicit none
    integer, parameter :: i18=selected_int_kind(18);
    integer, parameter :: sp =selected_real_kind(6, 37)
    integer, parameter :: dp =selected_real_kind(15, 307)
end module set_precision

! +------------------+
! |  Timing          |
! +------------------+
module time

    implicit none
    integer, save :: t_m, t_n, t_o
    integer, save :: val0(8), val1(8), val2(8)   
    real, save    :: etime1(2), etime2(2), tresult
    real, save    :: t0, t1, t2, t3 ! t4, tcpu1, tcpu2, twall1, twall2

    real, save    :: tloop_beg_dat, tloop_beg_mul, tloop_beg_snd, tloop_beg_cpy, &
                     tloop_beg_alp, tloop_beg_bet, tloop_beg_swp, tloop_beg_mv

    real, save    :: tloop_end_dat, tloop_end_mul, tloop_end_snd, tloop_end_cpy, &
                     tloop_end_alp, tloop_end_bet, tloop_end_swp, tloop_end_mv

    real, save    :: tloop_dat, tloop_mul, tloop_snd, tloop_cpy, &
                     tloop_cpu, tloop_alp, tloop_bet, tloop_swp, &
                     tloop_mv
    logical(kind=1), parameter :: print_more=.false.
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
    integer mpierr, rank, procs, tag, sendreq, recvreq, req(2)
    integer sendst, recvst
    integer status(MPI_STATUS_SIZE)
! Openmp variables
    !integer OMP_GET_THREAD_NUM, OMP_GET_NUM_THREADS
    integer tid !, OMP_GET_THREAD_NUM
    integer ntd !, OMP_GET_NUM_PROCS, OMP_get_num_threads
    integer iter

  end module mpi_stuff

