#ifdef CESMCOUPLED
module dems_comp_nuopc
#else
module cdeps_dems_comp
#endif

  !----------------------------------------------------------------------------
  ! This is the NUOPC cap for DEMS (Data Emissions)
  !----------------------------------------------------------------------------

  use ESMF             , only : ESMF_VM, ESMF_VMBroadcast
  use ESMF             , only : ESMF_Mesh, ESMF_GridComp, ESMF_SUCCESS, ESMF_LogWrite
  use ESMF             , only : ESMF_GridCompSetEntryPoint, ESMF_METHOD_INITIALIZE
  use ESMF             , only : ESMF_MethodRemove, ESMF_State, ESMF_Clock
  use ESMF             , only : ESMF_LOGMSG_INFO, ESMF_ClockGet
  use ESMF             , only : ESMF_Time, ESMF_TimeGet, ESMF_Field, ESMF_MAXSTR
  use ESMF             , only : ESMF_TimeInterval, operator(+), ESMF_TimeIntervalGet
  use ESMF             , only : ESMF_TraceRegionEnter, ESMF_TraceRegionExit, ESMF_GridCompGet
  use ESMF             , only : ESMF_MeshSet, ESMF_MeshGet, ESMF_DistGrid, ESMF_DistGridGet
  use NUOPC            , only : NUOPC_CompDerive, NUOPC_CompSetEntryPoint, NUOPC_CompSpecialize
  use NUOPC            , only : NUOPC_CompAttributeGet, NUOPC_Advertise
  use NUOPC_Model      , only : model_routine_SS        => SetServices
  use NUOPC_Model      , only : model_label_Advance     => label_Advance
  use NUOPC_Model      , only : model_label_SetRunClock => label_SetRunClock
  use NUOPC_Model      , only : model_label_Finalize    => label_Finalize
  use NUOPC_Model      , only : NUOPC_ModelGet, setVM
  use shr_kind_mod     , only : r8=>shr_kind_r8, i8=>shr_kind_i8, cl=>shr_kind_cl, cx=>shr_kind_cx, cs=>shr_kind_cs
  use shr_log_mod      , only : shr_log_setLogUnit, shr_log_error
  use shr_cal_mod      , only : shr_cal_ymd2date
  use shr_string_mod   , only : shr_string_toLower
  use dshr_methods_mod , only : chkerr, dshr_state_getfldptr, dshr_fldbun_getfldptr
  use dshr_strdata_mod , only : shr_strdata_type, shr_strdata_advance
  use dshr_strdata_mod , only : shr_strdata_init, shr_strdata_get_stream_count
  use dshr_strdata_mod , only : shr_strdata_get_stream_domain
  use dshr_stream_mod  , only : shr_stream_init_from_xml, shr_stream_init_from_esmfconfig
  use dshr_mod         , only : dshr_model_initphase, dshr_init, dshr_restart_write
  use dshr_mod         , only : dshr_set_runclock, dshr_mesh_init, dshr_restart_read
  use dshr_mod         , only : main_task
  use dshr_dfield_mod  , only : dfield_type, dshr_dfield_add, dshr_dfield_copy
  use dshr_fldlist_mod , only : fldlist_type, dshr_fldlist_add, dshr_fldlist_realize

  implicit none
  private

  public  :: SetServices
  public  :: SetVM
  private :: InitializeAdvertise
  private :: InitializeRealize
  private :: ModelAdvance
  private :: dems_comp_run
  private :: ModelFinalize

  !--------------------------------------------------------------------------
  ! Private module data
  !--------------------------------------------------------------------------

  type(shr_strdata_type)       :: sdat
  type(ESMF_Mesh)              :: model_mesh
  integer                      :: mpicom
  integer                      :: my_task
  logical                      :: mainproc
  integer                      :: inst_index
  character(len=16)            :: inst_suffix = ""
  integer                      :: logunit
  logical                      :: restart_read
  character(CL)                :: case_name
  character(len=*) , parameter :: nullstr = 'null'

  ! dems_in namelist input
  character(CX)                :: nlfilename = nullstr
  character(CX)                :: streamfilename = nullstr
  character(CL)                :: dataMode = nullstr
  character(CX)                :: model_meshfile = nullstr
  character(CX)                :: model_maskfile = nullstr
  character(CL)                :: restfilm = nullstr
  integer                      :: nx_global = 0
  integer                      :: ny_global = 0
  logical                      :: skip_restart_read = .false.
  logical                      :: export_all = .false.

  ! linked lists
  type(fldList_type) , pointer :: fldsImport => null()
  type(fldList_type) , pointer :: fldsExport => null()
  type(dfield_type)  , pointer :: dfields    => null()

  ! model mask and model fraction
  real(r8), pointer            :: model_frac(:) => null()
  integer , pointer            :: model_mask(:) => null()

  ! constants
  integer                      :: idt
#ifdef CESMCOUPLED
  character(*)     , parameter :: modName       = "(dems_comp_nuopc)"
#else
  character(*)     , parameter :: modName       = "(cdeps_dems_comp)"
#endif

  character(*), parameter :: u_FILE_u = __FILE__

contains

  subroutine SetServices(dems_comp, rc)
    type(ESMF_GridComp)  :: dems_comp
    integer, intent(out) :: rc

    character(len=*),parameter  :: subname=trim(modName)//':(SetServices) '

    rc = ESMF_SUCCESS
    call ESMF_LogWrite(subname//' called', ESMF_LOGMSG_INFO)

    call NUOPC_CompDerive(dems_comp, model_routine_SS, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_GridCompSetEntryPoint(dems_comp, ESMF_METHOD_INITIALIZE, &
         userRoutine=dshr_model_initphase, phase=0, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSetEntryPoint(dems_comp, ESMF_METHOD_INITIALIZE, &
         phaseLabelList=(/"IPDv01p1"/), userRoutine=InitializeAdvertise, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSetEntryPoint(dems_comp, ESMF_METHOD_INITIALIZE, &
         phaseLabelList=(/"IPDv01p3"/), userRoutine=InitializeRealize, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSpecialize(dems_comp, specLabel=model_label_Advance, specRoutine=ModelAdvance, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_MethodRemove(dems_comp, label=model_label_SetRunClock, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return
    call NUOPC_CompSpecialize(dems_comp, specLabel=model_label_SetRunClock, specRoutine=dshr_set_runclock, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSpecialize(dems_comp, specLabel=model_label_Finalize, specRoutine=ModelFinalize, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_LogWrite(subname//' done', ESMF_LOGMSG_INFO)
  end subroutine SetServices

  subroutine InitializeAdvertise(gcomp, importState, exportState, clock, rc)
    use NUOPC, only : NUOPC_FieldDictionaryAddEntry
    use shr_nl_mod, only:  shr_nl_find_group_name
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: importState, exportState
    type(ESMF_Clock)     :: clock
    integer, intent(out) :: rc

    integer           :: nu, ierr
    type(ESMF_VM)     :: vm
    character(len=*),parameter :: subname=trim(modName) // ':(InitializeAdvertise) '
    character(*)    ,parameter :: F00 = "('(" // trim(modName) // ") ',8a)"
    character(*)    ,parameter :: F01 = "('(" // trim(modName) // ") ',a,2x,i8)"
    character(*)    ,parameter :: F02 = "('(" // trim(modName) // ") ',a,l6)"

    namelist / dems_nml / &
         datamode, model_meshfile, model_maskfile, nx_global, ny_global, &
         restfilm, skip_restart_read, export_all

    rc = ESMF_SUCCESS

    call NUOPC_CompAttributeGet(gcomp, name='case_name', value=case_name, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call dshr_init(gcomp, 'DEMS', mpicom, my_task, inst_index, inst_suffix, &
         "", 0, 0, 0, logunit, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    mainproc = (my_task == main_task)

    if (my_task == main_task) then
       nlfilename = "dems_in"//trim(inst_suffix)
       open (newunit=nu,file=trim(nlfilename),status="old",action="read")
       call shr_nl_find_group_name(nu, 'dems_nml', status=ierr)
       if (ierr == 0) then
          read (nu,nml=dems_nml,iostat=ierr)
       end if
       close(nu)
       if (ierr > 0) then
          rc = ierr
          call shr_log_error(subName//': namelist read error '//trim(nlfilename), rc=rc)
          return
       end if
    end if

    call ESMF_GridCompGet(gcomp, vm=vm, rc=rc)
    call ESMF_VMBroadcast(vm, datamode, CL, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, model_meshfile, CX, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, model_maskfile, CX, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, nx_global, 1, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, ny_global, 1, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, restfilm, CL, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, skip_restart_read, 1, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, export_all, 1, main_task, rc=rc)

    if (my_task == main_task) then
       write(logunit,F00)' case_name      = ',trim(case_name)
       write(logunit,F00)' datamode       = ',trim(datamode)
       write(logunit,F00)' model_meshfile = ',trim(model_meshfile)
       write(logunit,F01)' nx_global      = ',nx_global
       write(logunit,F01)' ny_global      = ',ny_global
       write(logunit,F02)' export_all     = ',export_all
    end if

    ! Dynamically advertise fields based on streams (Zero hardcoding)
    call dems_advertise_fields(gcomp, exportState, rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

  end subroutine InitializeAdvertise

  subroutine InitializeRealize(gcomp, importState, exportState, clock, rc)
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: importState, exportState
    type(ESMF_Clock)     :: clock
    integer, intent(out) :: rc

    type(ESMF_TimeInterval) :: timeStep
    type(ESMF_TIME)         :: currTime
    integer                 :: current_ymd, current_tod, mon
    integer                 :: yr, day
    integer(i8)             :: stepno
    character(len=*), parameter :: subname=trim(modName)//':(InitializeRealize) '

    rc = ESMF_SUCCESS
    call ESMF_LogWrite(subname//' called', ESMF_LOGMSG_INFO)

    call ESMF_TraceRegionEnter('dems_strdata_init')
    call dshr_mesh_init(gcomp, sdat, nullstr, logunit, 'DEMS', nx_global, ny_global, &
         model_meshfile, model_maskfile, model_mesh, model_mask, model_frac, restart_read, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    streamfilename = 'dems.streams'//trim(inst_suffix)
#ifndef DISABLE_FoX
    streamfilename = trim(streamfilename)//'.xml'
#endif

#ifdef CESMCOUPLED
    sdat%pio_subsystem => shr_pio_getiosys('DEMS')
    sdat%io_type       =  shr_pio_getiotype('DEMS')
    sdat%io_format     =  shr_pio_getioformat('DEMS')
#endif
    sdat%mainproc = mainproc

#ifndef DISABLE_FoX
    call shr_stream_init_from_xml(streamfilename, sdat%stream, sdat%mainproc, logunit, &
         sdat%pio_subsystem, sdat%io_type, sdat%io_format, 'DEMS', rc=rc)
#else
    call shr_stream_init_from_esmfconfig(streamfilename, sdat%stream, logunit, &
         sdat%pio_subsystem, sdat%io_type, sdat%io_format, rc=rc)
#endif
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    allocate(sdat%pstrm(shr_strdata_get_stream_count(sdat)))

    ! Enforce conservative regridding for emissions
    block
      integer :: ns
      do ns = 1, shr_strdata_get_stream_count(sdat)
        if (trim(sdat%stream(ns)%mapalgo) == 'bilinear') then
           call ESMF_LogWrite('SEVERE WARNING: Bilinear regridding of emissions violates mass conservation. Forcing conservative regridding.', &
                              ESMF_LOGMSG_INFO)
           sdat%stream(ns)%mapalgo = 'consf'
        else if (trim(sdat%stream(ns)%mapalgo) == 'not_set' .or. trim(sdat%stream(ns)%mapalgo) == 'null' .or. &
                 trim(sdat%stream(ns)%mapalgo) == '') then
           sdat%stream(ns)%mapalgo = 'consf'
        end if
      end do
    end block

    sdat%model_mesh = model_mesh
    call shr_strdata_init(sdat, clock, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    ! ESMF_MeshSet does not support elementArea directly in 8.x.
    ! Element areas are handled by ESMF during regridding if they are not provided during Mesh creation.
    ! For Session 2, we have ensured mapalgo is set to 'consf' or 'consd',
    ! which triggers ESMF conservative regridding.

    call ESMF_TraceRegionExit('dems_strdata_init')

    call dshr_fldlist_realize(exportState, fldsExport, "", 0, model_mesh, &
         subname//':demsExport', export_all, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_ClockGet(clock, currTime=currTime, timeStep=timeStep, advanceCount=stepno, rc=rc)
    call ESMF_TimeGet(currTime, yy=yr, mm=mon, dd=day, s=current_tod, rc=rc)
    call shr_cal_ymd2date(yr, mon, day, current_ymd)
    call ESMF_TimeIntervalGet(timeStep, s=idt, rc=rc)

    call dems_comp_run(gcomp, importstate, exportstate, current_ymd, current_tod, mon, &
         restart_write=.false., rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

  end subroutine InitializeRealize

  subroutine ModelAdvance(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc

    type(ESMF_State)        :: importState, exportState
    type(ESMF_Clock)        :: clock
    type(ESMF_Time)         :: currTime, nextTime
    type(ESMF_TimeInterval) :: timeStep
    logical                 :: restart_write
    integer                 :: next_ymd, next_tod, mon
    integer                 :: yr, day
    character(len=*),parameter  :: subname=trim(modName)//':(ModelAdvance) '

    rc = ESMF_SUCCESS
    call ESMF_TraceRegionEnter(subname)
    call shr_log_setLogUnit(logunit)

    call NUOPC_ModelGet(gcomp, modelClock=clock, importState=importState, exportState=exportState, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_ClockGet(clock, currTime=currTime, timeStep=timeStep, rc=rc)
    nextTime = currTime + timeStep
    call ESMF_TimeGet(nextTime, yy=yr, mm=mon, dd=day, s=next_tod, rc=rc)
    call shr_cal_ymd2date(yr, mon, day, next_ymd)

    ! Logic for restart
    restart_write = .false. ! Placeholder

    call dems_comp_run(gcomp, importstate, exportstate, next_ymd, next_tod, mon, restart_write, rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call ESMF_TraceRegionExit(subname)
  end subroutine ModelAdvance

  subroutine dems_comp_run(gcomp, importState, exportState, target_ymd, target_tod, target_mon, &
       restart_write, rc)
    use nuopc_shr_methods, only : shr_get_rpointer_name
    type(ESMF_GridComp)    , intent(inout) :: gcomp
    type(ESMF_State)       , intent(inout) :: importState, exportState
    integer                , intent(in)    :: target_ymd, target_tod, target_mon
    logical                , intent(in)    :: restart_write
    integer                , intent(out)   :: rc

    logical, save :: first_time = .true.
    character(len=CL) :: rpfile
    character(*), parameter :: subName = '(dems_comp_run) '

    rc = ESMF_SUCCESS
    call ESMF_TraceRegionEnter('DEMS_RUN')

    if (first_time) then
       block
         type(fldlist_type), pointer :: fld
         integer :: ns, nf
         logical :: is_aggregated
         fld => fldsExport
         do while (associated(fld))
            ! Skip fields that are aggregated (summed) in any stream.
            ! These are handled by the custom summation logic below.
            is_aggregated = .false.
            do ns = 1, shr_strdata_get_stream_count(sdat)
               do nf = 1, sdat%stream(ns)%nvars
                  if (trim(sdat%stream(ns)%varlist(nf)%nameinmodel) == trim(fld%stdname) .and. &
                      trim(sdat%stream(ns)%varlist(nf)%aggregate) == 'sum') then
                     is_aggregated = .true.
                     exit
                  endif
               end do
               if (is_aggregated) exit
            end do

            if (.not. is_aggregated) then
               call dshr_dfield_add(dfields, sdat, trim(fld%stdname), trim(fld%stdname), &
                    exportState, logunit, mainproc, rc=rc)
               if (chkerr(rc,__LINE__,u_FILE_u)) return
            endif
            fld => fld%next
         end do
       end block

       if (restart_read .and. .not. skip_restart_read) then
          call shr_get_rpointer_name(gcomp, 'dems', target_ymd, target_tod, rpfile, 'read', rc)
          call dshr_restart_read(restfilm, rpfile, logunit, my_task, mpicom, sdat, rc)
       end if
       first_time = .false.
    end if

    call shr_strdata_advance(sdat, target_ymd, target_tod, logunit, 'dems', rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    call dshr_dfield_copy(dfields, sdat, rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    ! Sector Aggregation (Summation)
    block
      integer :: ns, nf, n, rank, i
      real(r8), pointer :: export_ptr1(:), strm_ptr1(:)
      real(r8), pointer :: export_ptr2(:,:), strm_ptr2(:,:)
      character(CS) :: model_name
      character(CS), allocatable :: aggregated_flds(:)
      integer :: num_agg

      ! 1. Identify all fields that will be aggregated and zero them out
      num_agg = 0
      do ns = 1, shr_strdata_get_stream_count(sdat)
         num_agg = num_agg + sdat%stream(ns)%nvars
      end do
      allocate(aggregated_flds(num_agg))
      num_agg = 0
      do ns = 1, shr_strdata_get_stream_count(sdat)
         do nf = 1, sdat%stream(ns)%nvars
            if (trim(sdat%stream(ns)%varlist(nf)%aggregate) == 'sum') then
               model_name = sdat%stream(ns)%varlist(nf)%nameinmodel
               ! Check if already zeroed
               do i = 1, num_agg
                  if (aggregated_flds(i) == model_name) goto 10
               end do
               num_agg = num_agg + 1
               aggregated_flds(num_agg) = model_name
               call dshr_state_getfldptr(exportState, trim(model_name), export_ptr1, export_ptr2, allowNullReturn=.true., rc=rc)
               if (associated(export_ptr1)) export_ptr1(:) = 0.0_r8
               if (associated(export_ptr2)) export_ptr2(:,:) = 0.0_r8
10             continue
            endif
         end do
      end do

      ! 2. Sum sectors into export fields
      do ns = 1, shr_strdata_get_stream_count(sdat)
         do nf = 1, sdat%stream(ns)%nvars
            if (trim(sdat%stream(ns)%varlist(nf)%aggregate) == 'sum') then
               model_name = sdat%stream(ns)%varlist(nf)%nameinmodel
               call dshr_fldbun_getfldptr(sdat%pstrm(ns)%fldbun_model, &
                    trim(sdat%stream(ns)%varlist(nf)%nameinfile), &
                    fldptr1=strm_ptr1, fldptr2=strm_ptr2, rank=rank, rc=rc)
               if (chkerr(rc,__LINE__,u_FILE_u)) return

               if (rank == 1) then
                  call dshr_state_getfldptr(exportState, trim(model_name), fldptr1=export_ptr1, rc=rc)
                  export_ptr1(:) = export_ptr1(:) + strm_ptr1(:)
               else if (rank == 2) then
                  call dshr_state_getfldptr(exportState, trim(model_name), fldptr2=export_ptr2, rc=rc)
                  export_ptr2(:,:) = export_ptr2(:,:) + strm_ptr2(:,:)
               endif
               if (mainproc) write(logunit,*) 'DEMS: Summing sector ', &
                    trim(sdat%stream(ns)%varlist(nf)%nameinfile), ' into ', trim(model_name)
            endif
         end do
      end do
      deallocate(aggregated_flds)
    end block

    if (restart_write) then
       call shr_get_rpointer_name(gcomp, 'dems', target_ymd, target_tod, rpfile, 'write', rc)
       call dshr_restart_write(rpfile, case_name, 'dems', inst_suffix, target_ymd, target_tod, logunit, &
            my_task, sdat, rc)
    end if

    if (mainproc) write(logunit,*) 'dems : model date ', target_ymd, target_tod
    call ESMF_TraceRegionExit('DEMS_RUN')
  end subroutine dems_comp_run

  subroutine ModelFinalize(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    rc = ESMF_SUCCESS
    if (my_task == main_task) then
       write(logunit,*) 'dems : end of main integration loop'
    end if
  end subroutine ModelFinalize

  subroutine dems_advertise_fields(gcomp, exportState, rc)
#ifndef DISABLE_FoX
    use FoX_DOM, only : extractDataContent, destroy, Node, NodeList, parseFile, getElementsByTagname
    use FoX_DOM, only : getLength, item
#endif
    use ESMF, only : ESMF_ConfigCreate, ESMF_ConfigLoadFile, ESMF_ConfigGetLen
    use ESMF, only : ESMF_ConfigGetAttribute, ESMF_Config
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: exportState
    integer, intent(out) :: rc

#ifndef DISABLE_FoX
    type(Node)     , pointer :: Sdoc, p, streamnode, varnode
    type(NodeList) , pointer :: streamlist, varlist
#endif
    type(ESMF_Config)        :: cf
    type(ESMF_VM)            :: vm
    character(len=CL)        :: tmpstr, model_name
    integer                  :: i, n, nstrms, nvars, status, nagg, k
    logical                  :: already_added, found
    character(2)             :: mystrm
    character(len=ESMF_MAXSTR), allocatable :: strm_tmpstrings(:)
    character(len=CL), allocatable :: all_names(:)

    rc = ESMF_SUCCESS

    call ESMF_GridCompGet(gcomp, vm=vm, rc=rc)
    if (chkerr(rc,__LINE__,u_FILE_u)) return

    if (mainproc) then
      streamfilename = 'dems.streams'//trim(inst_suffix)
#ifndef DISABLE_FoX
    streamfilename = trim(streamfilename)//'.xml'

    Sdoc => parseFile(streamfilename, iostat=status)
      if (status == 0) then
         streamlist => getElementsByTagname(Sdoc, "stream_info")
         nstrms = getLength(streamlist)
         nagg = 0
         do i = 1, nstrms
            streamnode => item(streamlist, i-1)
            p => item(getElementsByTagname(streamnode, "datavars"), 0)
            if (associated(p)) nagg = nagg + getLength(getElementsByTagname(p, "var"))
         end do
         allocate(all_names(nagg))
         nagg = 0
         do i = 1, nstrms
            streamnode => item(streamlist, i-1)
            p => item(getElementsByTagname(streamnode, "datavars"), 0)
            if (associated(p)) then
               varlist => getElementsByTagname(p, "var")
               nvars = getLength(varlist)
               do n = 1, nvars
                  varnode => item(varlist, n-1)
                  call extractDataContent(varnode, tmpstr)
                  call get_model_name(tmpstr, model_name)
                  nagg = nagg + 1
                  all_names(nagg) = model_name
               end do
            endif
         end do
         call destroy(Sdoc)
         goto 100
      endif
#endif
      ! Fallback to ESMF Config parser
      cf = ESMF_ConfigCreate(rc=rc)
      call ESMF_ConfigLoadFile(config=cf, filename=trim(streamfilename), rc=rc)
      if (rc == ESMF_SUCCESS) then
         nstrms = ESMF_ConfigGetLen(config=cf, label='stream_info:', rc=rc)
         nagg = 0
         do i = 1, nstrms
            write(mystrm,"(I2.2)") i
            nagg = nagg + ESMF_ConfigGetLen(config=cf, label="stream_data_variables"//mystrm//':', rc=rc)
         end do
         allocate(all_names(nagg))
         nagg = 0
         do i = 1, nstrms
            write(mystrm,"(I2.2)") i
            nvars = ESMF_ConfigGetLen(config=cf, label="stream_data_variables"//mystrm//':', rc=rc)
            if (nvars > 0) then
               allocate(strm_tmpstrings(nvars))
               call ESMF_ConfigGetAttribute(cf, valueList=strm_tmpstrings, label="stream_data_variables"//mystrm//':', rc=rc)
               do n = 1, nvars
                  call get_model_name(strm_tmpstrings(n), model_name)
                  nagg = nagg + 1
                  all_names(nagg) = model_name
               end do
               deallocate(strm_tmpstrings)
            endif
         end do
      endif
    endif

100 continue
    ! Broadcast field names to all tasks
    call ESMF_VMBroadcast(vm, nagg, 1, main_task, rc=rc)
    if (.not. mainproc) allocate(all_names(nagg))
    call ESMF_VMBroadcast(vm, all_names, CL*nagg, main_task, rc=rc)

    ! All tasks advertise fields
    do i = 1, nagg
       model_name = all_names(i)
       already_added = .false.
       block
         type(fldlist_type), pointer :: fld
         fld => fldsExport
         do while (associated(fld))
            if (trim(fld%stdname) == trim(model_name)) then
               already_added = .true.
               exit
            endif
            fld => fld%next
         end do
       end block

       if (.not. already_added) then
          call dshr_fldList_add(fldsExport, trim(model_name))
          call NUOPC_FieldDictionaryAddEntry(standardName=trim(model_name), units='kg m-2 s-1', rc=rc)
          call NUOPC_Advertise(exportState, standardName=trim(model_name), rc=rc)
       endif
    end do
    deallocate(all_names)

  contains

    subroutine get_model_name(line, name)
       character(len=*), intent(in) :: line
       character(len=*), intent(out) :: name
       character(len=CL) :: lstr
       integer :: pos
       lstr = adjustl(line)
       pos = scan(lstr, ' ')
       lstr = adjustl(lstr(pos+1:))
       pos = scan(lstr, ' ')
       if (pos > 0) then
          name = lstr(1:pos-1)
       else
          name = trim(lstr)
       endif
    end subroutine get_model_name

  end subroutine dems_advertise_fields

  subroutine SetVM(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    call setVM(gcomp, rc=rc)
  end subroutine SetVM

#ifdef CESMCOUPLED
end module dems_comp_nuopc
#else
end module cdeps_dems_comp
#endif
