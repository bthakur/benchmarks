! +------------------+
! | Lanczos Stuff    |
! +------------------+
  module lanczos_stuff

    use time
    use set_precision
    use mpi_stuff
    implicit none

! Lanczos vectors: distributed
    real, allocatable :: u(:), v(:), w(:), &
                         alpha(:), beta(:)
    real, save        :: alpha_local, alpha_global, &
                         beta_local, beta_global

! Dimensions
    integer iter_lanczos, n_local

! Variables: Rows and cols
    integer(kind=i18)  :: mrow, ncol;
    integer(kind=i18)  :: rdel,cdel
    integer(kind=i18)  :: irow, jcol, max_block, row_block,&
                        row_start,row_end,&
                        col_start, col_end;
    integer(kind=i18), allocatable  :: &
                       row_ini(:), row_fin(:)

! Timing variables
    !real :: t0, t1, t2, t3, tcpu
    !integer :: val0(8), val1(8), val2(8)

  contains

  function  fmat(ir, jc)

    implicit none

    real fmat
    integer(kind=i18) :: ir, jc

    !write(*,*) ir,jc
    fmat=1.0
    !write(*,*)fmat
    !if (abs(ir-jc).gt.2) fmat=1.0
    if (ir.eq.jc) fmat=float(ir)
    !if (abs(ir-jc).eq.2) fmat=float(ir+jc)
    !if (abs(jc-ir).eq.1) fmat=1.0
    !if ((ir-jc).eq.1) mat=1.0
    !if (ir.gt.mrow .or. jc.gt.mrow) mat=0.0
    !write(*,*)ir,jc,fmat

  end function

  subroutine partition_rows

    implicit none

! Row partitioning
    row_block = (mrow+nproc)/nproc
    max_block = row_block

    allocate(row_ini(0:nproc-1), row_fin(0:nproc-1))
    row_ini=-1
    row_fin=-1
    !write(*,'(a4,i12,a2,i12,i12,a2,i12,i12)')&
    !            'Row:', row_start,":", row_end, &
    !                    col_start,":",col_end, max_block
    row_ini(0)= 0
    row_fin(0)= min(mrow, max_block-1)
    do irow=1,nproc-1
       if(row_fin(irow-1).eq.(-1)) then
          row_ini(irow)= -1
          row_fin(irow)= -1
       else if (row_fin(irow-1).eq.(mrow)) then
          row_ini(irow)= -1
          row_fin(irow)= -1
       else 
          row_ini(irow)= min(mrow, row_ini(irow-1)+max_block)
          row_fin(irow)= min(mrow, row_fin(irow-1)+max_block)
       end if
    if (rank==0) &
        write(*,'(a6,2i6, 2i12)')"rank", &
          rank, irow, row_ini(irow), row_fin(irow)
    end do
    if (rank==0) &
        write(*,'(a6,2i6, 2i12)')"rank", &
          rank, 0, row_ini(0), row_fin(0)

    row_start= row_ini(rank)
    row_end  = row_fin(rank)
    col_start= row_start
    col_end  = row_end

! Allocate and Initialize
    !write(*,*)rank, max_block-1
    allocate(u(0:max_block-1), v(0:max_block-1), w(0:max_block-1))

!!$OMP PARALLEL &
!!$OMP& DEFAULT(PRIVATE) SHARED(v) PRIVATE(irow)
!!$OMP& SCHEDULE(SYNAMIC)

!$OMP PARALLEL DO
    do irow=0,max_block-1
        w(irow)=0.0
        u(irow)=0.0
        v(irow)=0.0
    end do
!!$OMP ENDDO

    if (rank==0) &
    Write(6,*)'Allocate and Initialize'

!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(irow)
!$OMP DO
    do irow=0, max_block-1
    if( (row_start.ne.(-1)).and.((rank*max_block+irow).le.mrow  ) ) then
      v(irow)=1.0!*rank
      !if (mod(irow,1000000000).eq.0) write(*,*) irow
    end if
    end do
!$OMP END DO
!$OMP END PARALLEL

! This is a bug : we need norm of whole vector, not partial
    !v=v/sqrt(sum(v*v))

    if (rank==0) &
    write(6,*)'Allocate and Initialize done', rank

    v=v/sqrt(float(mrow+1))

    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
  end subroutine

  subroutine lanczos_main

    use time
    implicit none

    integer, save :: i,j

    allocate(beta (iter_lanczos+1))
    allocate(alpha(iter_lanczos+1))
    beta =0.0
    alpha=0.0

  ! m-step lanczos starts 

    val0 = 0
    !tcpu1=0.d0
    !tcpu2=0.d0
    !twall1=0.d0
    etime1=0.d0
    etime2=0.d0
    call date_and_time(VALUES=val0)
    
    beta(1)=0.0
    do j=1, iter_lanczos
  ! Serial Lanczos matrix vector product
    val1=0
    call date_and_time(VALUES=val1)
    beta_global=beta(j)
    alpha_global=0.0

    if (rank==0) then
      write(6,*)"=========================="
      write(6,*)"Iteration ", j
      !write(*,*)'alpha-beta',j,rank, alpha_global, beta_global
    end if

    Call lanczos_matvec ! in v: out u

    beta(j+1) = beta_global
    alpha(j)  = alpha_global
    !call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    
    ! u=matmul(a,v)-beta(j)*u
    ! alpha(j)=DOT_PRODUCT(u, v)
    ! u=u-alpha(j)*v
    ! beta(j+1)= sqrt(sum(u*u))

  ! storing v_j   for first step of next iteration
  ! setting v_j+1 for next iteration
  ! swap u and v
    !do i=1,n_local
    !   va=v(i)
    !   v(i)=u(i)/beta(j+1)
    !   u(i)=va
    !end do
  !  
    val2=0
    call date_and_time(VALUES=val2)
    
    !t_iter= val2(7) -val1(7) + (val2(6)-val1(6))*60 +(val2(5)-val1(5))*3600
    !t_tot = t_tot+t_iter
 
    t_m=val0(2) + val0(3)*60*60*24 + val0(5)*3600 + val0(6)*60 + val0(7)
    t_n=val2(2) + val2(3)*60*60*24 + val2(5)*3600 + val2(6)*60 + val2(7)
    !if (rank==0) &
    !write(*,*) "Iter",j, alpha_global, beta_global, t_n - t_m
    !write(*,*)'j',j, alpha_global, beta_global, t_iter, t_tot

    call MPI_Barrier(MPI_COMM_WORLD, mpierr)

    end do
  end subroutine lanczos_main


  subroutine lanczos_matvec

    !include 'fpapi.h'
    use time
    implicit none
    real va, rmat
    integer irank
    !logical*1, parameter :: mpi_async=.false.
    !integer size
    logical*1, parameter :: mpi_async=.true.

    alpha_local=0.0
    beta_local =0.0
    !write(6,"(a2,i4,11f8.4)")"v",rank,v
    !write(*,"(a2,i4,11f8.4)")"i",rank,v(0:10)
    !write(*,"(a2,i4,11f8.4)")"i",rank,w
    !write(*,*)'t_m',t_m

    tloop_cpu=0.0
    tloop_mul=0.0
    tloop_snd=0.0
    tloop_cpy=0.0
    tloop_mv=0.0
    call cpu_time(t0)
    tloop_beg_mv= time_dt()

    do iter=1, nproc

      tloop_beg_dat= time_dt()
      tloop_beg_snd= tloop_beg_dat
      call cpu_time(t1)

      !if (rank==0) &
      !write(*,*)'Send/Recv'
      !write(*,'(a4,i6,i12,a2,i12,i12,a2,i12,i12,i20)')&
      !    'Row:',iter, row_start,":", row_end, &
      !            col_start,":",col_end,max_block, t0
      tag=1000*iter !+mod(rank-1+nproc,nproc) *  mod(rank+1,nproc)

      ! MPI Send/Recv
      !print *, v(1:10)
      !print *, max_block

    ! Matvec
    ! OpenMP Parallelization
    !!$OMP PARALLEL PRIVATE(tid, irow,jcol) SHARED(u,v,w)
    !!tid=OMP_GET_THREAD_NUM()
      !if (tid==0) then
        !write(*,*) "tid is ", tid
      if (mpi_async) then
      !if (.false.) then
        Call MPI_Irecv( u, max_block, MPI_REAL, mod(rank+1,nproc), tag, &
          MPI_COMM_WORLD, recvreq, mpierr )
        Call MPI_Isend( v, max_block,  MPI_REAL, mod(rank-1+nproc,nproc), tag,      &
          MPI_COMM_WORLD, sendreq, mpierr)
          req(1) = sendreq
          req(2) = recvreq
      else
      ! This has errors no more 
        do irank=0,nproc-1
        if (rank==irank) then
        Call MPI_Sendrecv(v, max_block, MPI_REAL, mod(irank-1+nproc,nproc), tag, &
                          u, max_block, MPI_REAL, mod(irank+1,nproc), tag, &
                          MPI_COMM_WORLD, status, mpierr )

        !call MPI_Get_count(status, MPI_CHARACTER, size, mpierr)
        end if
        end do
      end if

       tloop_beg_mul= time_dt()

! Hardware counters

!
       !$OMP PARALLEL
       tid=OMP_GET_THREAD_NUM()
       !$OMP DO SCHEDULE(static,1) PRIVATE(irow,jcol) 
       !!collapse(2)

       !write(*,*)"All other tid's", tid

    !do irow=row_start, row_end
    do irow=row_start, row_end,cdel

       ! remainder is not taken care of yet
       ! what if col_end-col_start is not divisible by cdel?
       ! that last iteration causes seg fault

       !do jcol=col_start, col_end!max_block/5
       do jcol=col_start, col_end, cdel !max_block/5

    !if (irow.gt.10 .and. (irow.lt.(mrow-10))) then
       !do jcol=col_start, col_end
        !if (abs(mat(irow,jcol)).gt..001 .and. abs(irow-jcol).eq.2 ) then
        !write(*,'(a4,3i4,2f8.4)')'tid',irow, irow,jcol,mat(irow,jcol),v(jcol-col_start)
        !end if
    !rmat=1.d0
    !if (irow.eq.jcol) rmat=float(irow)
    !if (abs(irow-jcol).eq.2) rmat=float(irow+jcol)
          !write(*,*)tid,irow, jcol , fmat(irow,jcol)
        ! write(*,*)irow, jcol , rmat,v(jcol-col_start)
        !w(irow-row_start)= w(irow-row_start) &
        !                  +fmat(irow,jcol)*v(jcol-col_start)
!write(6,'(2i4,a2,3i4,a4,i4)')rank,tid,':',irow,jcol, jcol-col_start, '..',jcol-col_start+3

! Assuming cdel=4
! Experimented with unrolling in 1.15. Did not help speedup, reverting in 1.16
w(irow-row_start)= w(irow-row_start)&
                          +fmat(irow,jcol)*v(jcol-col_start) !&
                          !+fmat(irow,jcol+1)*v(jcol-col_start+1) &
                          !+fmat(irow,jcol+2)*v(jcol-col_start+2) &
                          !+fmat(irow,jcol+3)*v(jcol-col_start+3) 

       end do
    !end if
    end do
    !$OMP END DO

    !!SCHEDULE (DYNAMIC)
    !write(*,*)'Thds',rank, tid, row_start, row_end
    !write(*,*)row_start, row_end, col_start, col_end
    !$OMP END PARALLEL

    call cpu_time(t2)
    tloop_end_mul= time_dt()
 
    !if (rank==0) &
    !write(*,'(a4,i6,i12,a2,i12,i12,a2,i12,i12,i20)')&
    !    'Out:',iter, row_start,":", row_end, &
    !            col_start,":",col_end,max_block, t_m

    !col_start=col_end+1
    !col_end  =min(mrow,col_start+max_block-1)
    !call shift_col_right
    !mod(rank+iter,nproc)
    !print *, 'loop computation over', rank

    col_start= row_ini(mod(rank+iter,nproc))
    col_end  = row_fin(mod(rank+iter,nproc))

    !if (rank==0) &
    !write(*,*)'Compute over'

    if (mpi_async) then 
    !if (.false.) then
    Call MPI_Waitall ( 2, req, MPI_STATUSES_IGNORE, mpierr )
    end if

    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    !val1=0
    !call date_and_time(VALUES=val1)
    !t_m= val1(2) + val1(3)*60*60*24 + val1(5)*3600 + val1(6)*60 + val1(7)&
    !   -t_o
    !if (rank==0) &
    !write(*,'(a4,i6,i12,a2,i12,i12,a2,i12,i12,i20)')&
    !    'Out:',iter, row_start,":", row_end, &
    !            col_start,":",col_end,max_block, t_m


    ! Copying for next iteration
    !if (rank==0) &
    !write(*,*)'Copying'
    !call date_and_time(VALUES=val1)
    !call date_and_time(VALUES=val1)
    tloop_end_snd= time_dt()
    tloop_beg_cpy=tloop_end_snd
    !tloop_end_snd=float(val1(2)+val1(3)*3600*24+val1(5)*3600+val1(6)*60+val1(7))&
    !   + val1(8)*.001
    !tloop_beg_cpy=float(val1(2)+val1(3)*3600*24+val1(5)*3600+val1(6)*60+val1(7))&
    !   + val1(8)*.001

    v=u;
    !Call MPI_Barrier(MPI_COMM_WORLD, mpierr)

    !call date_and_time(VALUES=val1)
    tloop_end_cpy= time_dt()
    !tloop_end_cpy=float(val1(2)+val1(3)*3600*24+val1(5)*3600+val1(6)*60+val1(7))&
    !   + val1(8)*.001

    tloop_mul= tloop_mul + tloop_end_mul-tloop_beg_mul
    tloop_snd= tloop_snd + tloop_end_snd-tloop_beg_snd
    tloop_cpy= tloop_cpy + tloop_end_cpy-tloop_beg_cpy
    tloop_cpu= tloop_cpu + t2-t1

    end do

    ! Unnecessary
    !Call MPI_Barrier(MPI_COMM_WORLD, mpierr)

    tloop_beg_dat= time_dt()
    !tloop_beg_dat=float(val1(2)+val1(3)*3600*24+val1(5)*3600+val1(6)*60+val1(7))&
    !   + val1(8)*.001
    !call cpu_time(tloop_beg_dat)

  ! Alpha
    tloop_beg_alp= time_dt()
    !if (rank==0) &
    !write(*,*)'Alpha'
    !$OMP PARALLEL DEFAULT(SHARED) PRIVATE(irow)
    !$OMP DO reduction(+:alpha_local)
    !!$OMP DO SCHEDULE(DYNAMIC) reduction(+:alpha_local)
    do irow=0, max_block-1
     alpha_local = alpha_local + w(irow)*v(irow)
    end do
    !$OMP END DO
    !$OMP END PARALLEL
    alpha_global=0.0
  ! Reduce alpha
    !if (rank==0) &
    !write(*,*)'Allreduce Alpha-v'
    Call MPI_Allreduce(alpha_local, alpha_global, 1, &
                       MPI_REAL, MPI_SUM, MPI_COMM_WORLD, mpierr)
  ! Substracting alpha*v
    w=w-alpha_global*v
  ! Clock it
    tloop_end_alp= time_dt()

  ! Beta
    tloop_beg_bet= time_dt()
    !if (rank==0) &
    !write(*,*)'Beta'
    !$OMP PARALLEL DEFAULT(SHARED) PRIVATE(irow)
    !$OMP DO reduction(+:beta_local)
    !!$OMP DO SCHEDULE(DYNAMIC) reduction(+:beta_local)
    do irow=0, max_block-1
     beta_local = beta_local + w(irow)*w(irow)
    end do
    !$OMP END DO
    !$OMP END PARALLEL
    !beta_local= sum(w*w)

  ! Reduce beta
    !if (rank==0) &
    !write(*,*)'Reduce Beta'
    Call MPI_Allreduce(beta_local, beta_global, 1, &
                       MPI_REAL, MPI_SUM, MPI_COMM_WORLD, mpierr)
    !if (rank==0) &
    !write(*,*)'Beta global'
    beta_global= sqrt(beta_global)

    tloop_end_bet= time_dt()

    tloop_beg_swp= time_dt()
    !write(*,*)'Swap'
    !$OMP PARALLEL DEFAULT(SHARED) PRIVATE(irow,va)
    !$OMP DO 
    !!SCHEDULE(DYNAMIC)
      do irow=0, max_block-1
        va=v(irow)
        v(irow)=w(irow)/beta_global
        w(irow)=-beta_global*va
      end do
    !$OMP END DO
    !$OMP END PARALLEL
  ! Clock it
    tloop_end_swp= time_dt()
    tloop_end_mv= time_dt()

    !write(*,'(a4,i6,i12,a2,i12,i12,a2,i12,i12,i20)')&
    !    'Ovr:',iter, row_start,":", row_end, &
    !            col_start,":",col_end,max_block, t_m
    call cpu_time(t3)
  ! Cpu times
    if (rank==0) then
    !write(*,*)"=========================="
    !write(*,*)"Iteration over"
    write(6,*)'Mul Cpu /Time: Loop ', tloop_cpu
    write(6,*)'Mul Date/Time: Loop ', tloop_mul
    write(6,*)'Snd Date/Time: Loop ', tloop_snd
    write(6,*)'Cpy Date/Time: Loop ', tloop_cpy
    write(6,*)'Alp Date/Time: Loop ', tloop_end_alp- tloop_beg_alp
    write(6,*)'Bet Date/Time: Loop ', tloop_end_bet- tloop_beg_bet
    write(6,*)"--------------------------"
    end if
    !if (rank==0) &
    !write(*,*)'Iter Cpu Time:  Full/Loop ', tcpu2, tcpu1
    !if (rank==0) &
    !write(*,*)'Iter Date/Time: Full/Loop ', twall2, twall1

    if (rank==0) &
    write(6,*)'Iter Cpu /Time: Loop ',t3-t0
    if (rank==0) &
    write(6,*)'Iter Date/Time: Loop ',tloop_end_mv-tloop_beg_mv
    if (rank==0) &
    write(6,*)"=========================="

  end subroutine lanczos_matvec

end module lanczos_stuff


! +------------------+
! | Main program     |
! +------------------+
  program test

    use mpi_stuff
    use lanczos_stuff
    use lapack_stuff

    implicit none

! Initialize MPI
    Call MPI_Init (mpierr)
    Call MPI_COMM_Size(MPI_COMM_WORLD, nproc, mpierr)
    Call MPI_COMM_Rank(MPI_COMM_WORLD, rank,  mpierr)

    !$omp parallel
    ntd = omp_get_num_threads();
    !$omp end parallel
    write(6,*)"This is proc", rank, "of", nproc, ntd

    !mrow=369999909999_i18 ! (0:mrow) works > 256 processors
    !mrow=  99999_i18
    rdel= 1_i18
    cdel= 1_i18
    !mrow= (nproc*ntd)*10000_i18 -1_i18
    mrow= (nproc*ntd)*1000_i18 -1_i18
    ! cdel*nproc: so max_block is divisible by cdel
    !print *, mrow

! Row partitioning
    if (rank==0) &
    Write(6,*)'Entering partitions',rank
    call partition_rows
    !Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    if (rank==0) &
    write(6,*)"Mrow:max_block", mrow,max_block
    iter_lanczos=5
    !call lanczos_matvec
    if (rank==0) &
    Write(6,*)'Entering main', rank

    !stop
! Papi profiling
    !call PAPI_library_init(PAPI_VER_COUNT)

    call lanczos_main

    if (.true.) then

! Print result
    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    deallocate(u,v,w, row_ini, row_fin)
    if (rank==0) then
       write(6,'(a6,11(f18.4,x))')'alpha', alpha(1:iter_lanczos)
       write(6,'(a6,11(f18.4,x))')'beta ', beta(2:iter_lanczos)
    end if
! Eigenvalues of tridiagonal matrix
    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    if (rank==0) then
       call s_stev('N',alpha(1:iter_lanczos), beta(2:iter_lanczos), iter_lanczos)
       write(6,*)'Info',info
       !write(*,'("Eigs",2x, 5(f16.4,x))')alpha(1:iter_lanczos)
       write(6,*)"Eigs", alpha(1:iter_lanczos)
       !call system('matlab -nodisplay -r  gen_lanczos && quit')
    end if

! Eigenvalues using dsyev
    Call MPI_Barrier(MPI_COMM_WORLD, mpierr)
    if (rank==0) then
       !call s_syev(job,part,ndim, syev_mat)
       !write(*,*)'Info',info
       !write(*,'("Eigs",2x, 5(f10.3,x))')alpha(1:iter_lanczos)
       !call system('matlab -nodisplay -r  gen_lanczos && quit')
    end if
  end if

! Finalize
  Call MPI_Finalize(mpierr)

end

