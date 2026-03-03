module cdeps_inline_mod
  use ESMF
  use NUOPC
  use dshr_mod         , only: dshr_pio_init
  use dshr_strdata_mod , only: shr_strdata_type
  use dshr_strdata_mod , only: shr_strdata_init_from_inline
  use dshr_strdata_mod , only: shr_strdata_advance
  use dshr_methods_mod , only: dshr_fldbun_getfldptr, chkerr
  use dshr_stream_mod  , only: shr_stream_init_from_esmfconfig

  implicit none
  private

  public :: cdeps_inline_init, cdeps_inline_advance, cdeps_get_field_ptr

  type(shr_strdata_type), allocatable, save :: sdat(:)
  integer, save :: logunit = 6

  character(len=*), parameter :: u_FILE_u = __FILE__

contains

  subroutine cdeps_inline_init(gcomp, model_clock, model_mesh, stream_file, rc)
    type(ESMF_GridComp), intent(in)  :: gcomp
    type(ESMF_Clock),    intent(in)  :: model_clock
    type(ESMF_Mesh),     intent(in)  :: model_mesh
    character(len=*),    intent(in)  :: stream_file
    integer,             intent(out) :: rc

    type(shr_strdata_type) :: sdatconfig
    character(len=ESMF_MAXSTR), allocatable :: f_list(:), v_list(:,:)
    integer :: ns, l, nstreams, mytask
    type(ESMF_VM) :: vm
    logical :: isPresent, isSet
    character(len=ESMF_MAXSTR) :: compname = 'CDEPS'
    character(len=ESMF_MAXSTR) :: cvalue, stream_name

    rc = ESMF_SUCCESS

    call ESMF_GridCompGet(gcomp, vm=vm, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return
    call ESMF_VMGet(vm, localPet=mytask, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompAttributeGet(gcomp, name='component_name', value=cvalue, isPresent=isPresent, isSet=isSet, rc=rc)
    if (rc == ESMF_SUCCESS .and. isPresent .and. isSet) then
       compname = trim(cvalue)
    endif

    ! Initialize PIO via CDEPS helper
    call dshr_pio_init(gcomp, sdatconfig, logunit, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    ! Load stream definitions from configuration
    call shr_stream_init_from_esmfconfig(trim(stream_file), sdatconfig%stream, logunit, &
         sdatconfig%pio_subsystem, sdatconfig%io_type, sdatconfig%io_format, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    if (.not. associated(sdatconfig%stream)) then
       rc = ESMF_FAILURE
       return
    endif

    nstreams = size(sdatconfig%stream)
    if (allocated(sdat)) deallocate(sdat)
    allocate(sdat(nstreams))

    do ns = 1, nstreams
      sdat(ns)%model_clock = model_clock
      sdat(ns)%model_mesh  = model_mesh
      sdat(ns)%pio_subsystem => sdatconfig%pio_subsystem
      sdat(ns)%io_type = sdatconfig%io_type
      sdat(ns)%io_format = sdatconfig%io_format

      allocate(f_list(sdatconfig%stream(ns)%nfiles))
      allocate(v_list(sdatconfig%stream(ns)%nvars, 2))

      do l = 1, sdatconfig%stream(ns)%nfiles
        f_list(l) = trim(sdatconfig%stream(ns)%file(l)%name)
      end do
      do l = 1, sdatconfig%stream(ns)%nvars
        v_list(l,1) = trim(sdatconfig%stream(ns)%varlist(l)%nameinfile)
        v_list(l,2) = trim(sdatconfig%stream(ns)%varlist(l)%nameinmodel)
      end do

      write(stream_name,fmt='(a,i2.2)') 'stream_', ns
      call shr_strdata_init_from_inline(sdat(ns), &
           my_task             = mytask, &
           logunit             = logunit, &
           compname            = trim(compname), &
           model_clock         = model_clock, &
           model_mesh          = model_mesh, &
           stream_name         = trim(stream_name), &
           stream_meshfile     = trim(sdatconfig%stream(ns)%meshfile), &
           stream_filenames    = f_list, &
           stream_fldlistFile  = v_list(:,1), &
           stream_fldListModel = v_list(:,2), &
           stream_yearFirst    = sdatconfig%stream(ns)%yearFirst, &
           stream_yearLast     = sdatconfig%stream(ns)%yearLast, &
           stream_yearAlign    = sdatconfig%stream(ns)%yearAlign, &
           stream_offset       = sdatconfig%stream(ns)%offset, &
           stream_taxmode      = trim(sdatconfig%stream(ns)%taxmode), &
           stream_dtlimit      = sdatconfig%stream(ns)%dtlimit, &
           stream_tintalgo     = trim(sdatconfig%stream(ns)%tInterpAlgo), &
           stream_lev_dimname  = trim(sdatconfig%stream(ns)%lev_dimname), &
           stream_mapalgo      = trim(sdatconfig%stream(ns)%mapalgo), &
           stream_src_mask     = sdatconfig%stream(ns)%src_mask_val, &
           stream_dst_mask     = sdatconfig%stream(ns)%dst_mask_val, &
           rc                  = rc)

      deallocate(f_list, v_list)
      if (chkerr(rc,__LINE__,u_FILE_u)) return
    end do
  end subroutine cdeps_inline_init

  subroutine cdeps_inline_advance(clock, rc)
    type(ESMF_Clock), intent(in)  :: clock
    integer,          intent(out) :: rc
    type(ESMF_Time) :: currTime
    integer :: yy, mm, dd, ss, mcdate, ns
    character(len=ESMF_MAXSTR) :: stream_name

    rc = ESMF_SUCCESS
    if (.not. allocated(sdat)) return

    call ESMF_ClockGet(clock, currTime=currTime, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return
    call ESMF_TimeGet(currTime, yy=yy, mm=mm, dd=dd, s=ss, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return
    mcdate = yy*10000 + mm*100 + dd

    do ns = 1, size(sdat)
      write(stream_name,fmt='(a,i2.2)') 'stream_', ns
      call shr_strdata_advance(sdat(ns), ymd=mcdate, tod=ss, logunit=logunit, istr=trim(stream_name), rc=rc)
      if (chkerr(rc,__LINE__,u_FILE_u)) return
    end do
  end subroutine cdeps_inline_advance

  subroutine cdeps_get_field_ptr(stream_idx, fldname, data_ptr, rc)
    integer,            intent(in)  :: stream_idx
    character(len=*),   intent(in)  :: fldname
    real(ESMF_KIND_R8), pointer     :: data_ptr(:)
    integer,            intent(out) :: rc

    rc = ESMF_SUCCESS
    if (.not. allocated(sdat)) then
       rc = ESMF_FAILURE
       return
    endif
    if (stream_idx < 1 .or. stream_idx > size(sdat)) then
       rc = ESMF_FAILURE
       return
    endif

    call dshr_fldbun_getFldPtr(sdat(stream_idx)%pstrm(1)%fldbun_model, &
                               trim(fldname), data_ptr, rc=rc)
  end subroutine cdeps_get_field_ptr

end module cdeps_inline_mod
