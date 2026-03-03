#ifdef CESMCOUPLED
module dems_comp_nuopc
#else
module cdeps_dems_comp
#endif

  !----------------------------------------------------------------------------
  ! This is the generic NUOPC cap for DEMS (Data Emissions)
  ! Supports gridded emissions and point source emissions via LocStream.
  !----------------------------------------------------------------------------

  use ESMF             , only : ESMF_VM, ESMF_VMBroadcast
  use ESMF             , only : ESMF_Mesh, ESMF_GridComp, ESMF_SUCCESS, ESMF_LogWrite
  use ESMF             , only : ESMF_GridCompSetEntryPoint, ESMF_METHOD_INITIALIZE
  use ESMF             , only : ESMF_MethodRemove, ESMF_State, ESMF_Clock, ESMF_TimeInterval
  use ESMF             , only : ESMF_State, ESMF_Field, ESMF_LOGMSG_INFO, ESMF_ClockGet
  use ESMF             , only : ESMF_Time, ESMF_Alarm, ESMF_TimeGet, ESMF_TimeInterval
  use ESMF             , only : operator(+), ESMF_TimeIntervalGet, ESMF_ClockGetAlarm
  use ESMF             , only : ESMF_AlarmIsRinging, ESMF_AlarmRingerOff, ESMF_StateGet
  use ESMF             , only : ESMF_FieldGet, ESMF_MAXSTR, ESMF_VMBroadcast
  use ESMF             , only : ESMF_TraceRegionEnter, ESMF_TraceRegionExit, ESMF_GridCompGet
  use ESMF             , only : ESMF_LocStream
  use NUOPC            , only : NUOPC_CompDerive, NUOPC_CompSetEntryPoint, NUOPC_CompSpecialize
  use NUOPC            , only : NUOPC_CompAttributeGet, NUOPC_Advertise
  use NUOPC_Model      , only : model_routine_SS        => SetServices
  use NUOPC_Model      , only : model_label_Advance     => label_Advance
  use NUOPC_Model      , only : model_label_SetRunClock => label_SetRunClock
  use NUOPC_Model      , only : model_label_Finalize    => label_Finalize
  use NUOPC_Model      , only : NUOPC_ModelGet, setVM
  use shr_kind_mod     , only : r8=>shr_kind_r8, i8=>shr_kind_i8, cl=>shr_kind_cl, cs=>shr_kind_cs
  use shr_kind_mod     , only : cx=>shr_kind_cx
  use shr_log_mod      , only : shr_log_setLogUnit, shr_log_error
  use dshr_methods_mod , only : dshr_state_diagnose, chkerr
  use dshr_strdata_mod , only : shr_strdata_type, shr_strdata_init_from_config, shr_strdata_advance
  use dshr_strdata_mod , only : shr_strdata_get_stream_pointer, shr_strdata_setOrbs
  use dshr_strdata_mod , only : shr_strdata_get_stream_count, shr_strdata_get_stream_locstream
  use dshr_mod         , only : dshr_model_initphase, dshr_init, dshr_restart_write
  use dshr_mod         , only : dshr_state_setscalar, dshr_set_runclock, dshr_log_clock_advance
  use dshr_mod         , only : dshr_mesh_init, dshr_check_restart_alarm, dshr_restart_read
  use dshr_mod         , only : dshr_orbital_init, dshr_orbital_update
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
  type(ESMF_Mesh)              :: model_mesh                ! model mesh
  integer                      :: mpicom                    ! mpi communicator
  integer                      :: my_task                   ! my task in mpi communicator mpicom
  logical                      :: mainproc                ! true of my_task == main_task
  integer                      :: inst_index                ! number of current instance (ie. 1)
  character(len=16)            :: inst_suffix = ""          ! char string associated with instance
  integer                      :: logunit                   ! logging unit number
  logical                      :: restart_read              ! start from restart
  character(CL)                :: case_name                 ! case name
  character(len=*) , parameter :: nullstr = 'null'

  ! dems_in namelist input
  character(CX)                :: nlfilename = nullstr
  character(CX)                :: streamfilename = nullstr
  character(CL)                :: datamode = 'COPYALL'
  character(CX)                :: model_meshfile = nullstr
  character(CX)                :: model_maskfile = nullstr
  integer                      :: nx_global = 0
  integer                      :: ny_global = 0
  character(CX)                :: restfilm = nullstr
  logical                      :: skip_restart_read = .false.
  logical                      :: export_all = .false.

  ! linked lists
  type(fldList_type) , pointer :: fldsExport => null()
  type(dfield_type)  , pointer :: dfields    => null()

  ! constants
  integer                      :: idt
  logical                      :: diagnose_data = .true.
  integer          , parameter :: main_task   = 0

#ifdef CESMCOUPLED
  character(*)     , parameter :: modName       = "(dems_comp_nuopc)"
#else
  character(*)     , parameter :: modName       = "(cdeps_dems_comp)"
#endif

  character(*), parameter :: u_FILE_u = __FILE__

!===============================================================================
contains
!===============================================================================

  subroutine SetServices(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc

    character(len=*),parameter  :: subname=trim(modName)//':(SetServices) '

    rc = ESMF_SUCCESS
    call ESMF_LogWrite(subname//' called', ESMF_LOGMSG_INFO)

    call NUOPC_CompDerive(gcomp, model_routine_SS, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call ESMF_GridCompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
         userRoutine=dshr_model_initphase, phase=0, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
         phaseLabelList=(/"IPDv01p1"/), userRoutine=InitializeAdvertise, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSetEntryPoint(gcomp, ESMF_METHOD_INITIALIZE, &
         phaseLabelList=(/"IPDv01p3"/), userRoutine=InitializeRealize, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSpecialize(gcomp, specLabel=model_label_Advance, specRoutine=ModelAdvance, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call ESMF_MethodRemove(gcomp, label=model_label_SetRunClock, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return
    call NUOPC_CompSpecialize(gcomp, specLabel=model_label_SetRunClock, specRoutine=dshr_set_runclock, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    call NUOPC_CompSpecialize(gcomp, specLabel=model_label_Finalize, specRoutine=ModelFinalize, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

  end subroutine SetServices

  !===============================================================================

  subroutine InitializeAdvertise(gcomp, importState, exportState, clock, rc)
    use shr_nl_mod, only:  shr_nl_find_group_name
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: importState, exportState
    type(ESMF_Clock)     :: clock
    integer, intent(out) :: rc

    integer           :: nu, ierr, ns, nf
    integer           :: bcasttmp(3)
    type(ESMF_VM)     :: vm
    character(len=*),parameter :: subname=trim(modName) // ':(InitializeAdvertise) '

    namelist / dems_nml / &
         datamode, model_meshfile, model_maskfile, nx_global, ny_global, &
         restfilm, skip_restart_read, export_all

    rc = ESMF_SUCCESS

    call NUOPC_CompAttributeGet(gcomp, name='case_name', value=case_name, rc=rc)
    call dshr_init(gcomp, 'EMS', mpicom, my_task, inst_index, inst_suffix, &
         logunit=logunit, rc=rc)
    mainproc = (my_task == main_task)

    if (my_task == main_task) then
       nlfilename = "dems_in"//trim(inst_suffix)
       open (newunit=nu,file=trim(nlfilename),status="old",action="read")
       call shr_nl_find_group_name(nu, 'dems_nml', status=ierr)
       read (nu,nml=dems_nml,iostat=ierr)
       close(nu)
       bcasttmp(1) = nx_global
       bcasttmp(2) = ny_global
       bcasttmp(3) = 0
       if(skip_restart_read) bcasttmp(3) = 1
    end if

    call ESMF_GridCompGet(gcomp, vm=vm, rc=rc)
    call ESMF_VMBroadcast(vm, datamode, CL, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, model_meshfile, CX, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, model_maskfile, CX, main_task, rc=rc)
    call ESMF_VMBroadcast(vm, bcasttmp, 3, main_task, rc=rc)
    nx_global = bcasttmp(1); ny_global = bcasttmp(2); skip_restart_read = (bcasttmp(3)==1)

    ! Generic advertisement: loop through streams and advertise all model fields
    streamfilename = 'dems.streams'//trim(inst_suffix)//'.xml'
    call shr_strdata_init_from_config(sdat, streamfilename, model_mesh, clock, 'EMS', logunit, rc=rc)

    do ns = 1, shr_strdata_get_stream_count(sdat)
       do nf = 1, size(sdat%pstrm(ns)%fldlist_model)
          call dshr_fldList_add(fldsExport, sdat%pstrm(ns)%fldlist_model(nf))
          call NUOPC_Advertise(exportState, standardName=trim(sdat%pstrm(ns)%fldlist_model(nf)), rc=rc)
       enddo
    enddo

  end subroutine InitializeAdvertise

  !===============================================================================

  subroutine InitializeRealize(gcomp, importState, exportState, clock, rc)
    type(ESMF_GridComp)  :: gcomp
    type(ESMF_State)     :: importState, exportState
    type(ESMF_Clock)     :: clock
    integer, intent(out) :: rc

    type(ESMF_TimeInterval) :: timeStep
    type(ESMF_TIME)         :: currTime
    integer                 :: current_ymd, current_tod, current_year, current_mon, current_day
    type(ESMF_LocStream)    :: lstream
    integer                 :: ns
    character(len=*), parameter :: subname=trim(modName)//':(InitializeRealize) '

    rc = ESMF_SUCCESS

    call dshr_mesh_init(gcomp, sdat, nullstr, logunit, 'EMS', nx_global, ny_global, &
         model_meshfile, model_maskfile, model_mesh, restart_read=restart_read, rc=rc)

    ! Realize fields. Check if point sources (nointp) are used.
    ! For simplicity, if any stream is point source, we realize on LocStream.
    ! A more robust generic cap would handle a mix, but usually DEMS is one or the other.
    do ns = 1, shr_strdata_get_stream_count(sdat)
       if (trim(sdat%stream(ns)%mapalgo) == 'nointp') then
          call shr_strdata_get_stream_locstream(sdat, ns, lstream, rc)
          call dshr_fldlist_realize(exportState, fldsExport, mesh=model_mesh, lstream=lstream, rc=rc)
          exit
       endif
       if (ns == shr_strdata_get_stream_count(sdat)) then
          call dshr_fldlist_realize(exportState, fldsExport, mesh=model_mesh, rc=rc)
       endif
    enddo

    call ESMF_ClockGet(clock, currTime=currTime, timeStep=timeStep, rc=rc)
    call ESMF_TimeGet(currTime, yy=current_year, mm=current_mon, dd=current_day, s=current_tod, rc=rc )
    call shr_cal_ymd2date(current_year, current_mon, current_day, current_ymd)
    call ESMF_TimeIntervalGet(timeStep, s=idt, rc=rc)

    call dems_comp_run(gcomp, importstate, exportstate, current_ymd, current_tod, rc=rc)

  end subroutine InitializeRealize

  !===============================================================================
  subroutine ModelAdvance(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc

    type(ESMF_State)        :: importState, exportState
    type(ESMF_Clock)        :: clock
    type(ESMF_Time)         :: currTime, nextTime
    type(ESMF_TimeInterval) :: timeStep
    integer                 :: next_ymd, next_tod, yr, mon, day
    character(len=*),parameter  :: subname=trim(modName)//':(ModelAdvance) '

    rc = ESMF_SUCCESS
    call NUOPC_ModelGet(gcomp, modelClock=clock, importState=importState, exportState=exportState, rc=rc)
    call ESMF_ClockGet(clock, currTime=currTime, timeStep=timeStep, rc=rc)
    nextTime = currTime + timeStep
    call ESMF_TimeGet(nextTime, yy=yr, mm=mon, dd=day, s=next_tod, rc=rc)
    call shr_cal_ymd2date(yr, mon, day, next_ymd)

    call dems_comp_run(gcomp, importstate, exportstate, next_ymd, next_tod, rc=rc)
  end subroutine ModelAdvance

  !===============================================================================
  subroutine dems_comp_run(gcomp, importState, exportState, target_ymd, target_tod, rc)
    type(ESMF_GridComp)    , intent(inout) :: gcomp
    type(ESMF_State)       , intent(inout) :: importState, exportState
    integer                , intent(in)    :: target_ymd, target_tod
    integer                , intent(out)   :: rc

    logical :: first_time = .true.
    character(*), parameter :: subName = '(dems_comp_run) '

    rc = ESMF_SUCCESS
    if (first_time) then
       call dems_init_dfields(exportState, rc)
       first_time = .false.
    endif

    call shr_strdata_advance(sdat, target_ymd, target_tod, logunit, 'dems', rc=rc)
    call dshr_dfield_copy(dfields, sdat, rc)
  end subroutine dems_comp_run

  subroutine dems_init_dfields(exportState, rc)
    type(ESMF_State), intent(inout) :: exportState
    integer, intent(out) :: rc
    integer :: ns, nf
    character(ESMF_MAXSTR) :: fldname
    rc = ESMF_SUCCESS
    do ns = 1, shr_strdata_get_stream_count(sdat)
       do nf = 1, size(sdat%pstrm(ns)%fldlist_model)
          fldname = trim(sdat%pstrm(ns)%fldlist_model(nf))
          call dshr_dfield_add(dfields, sdat, fldname, fldname, exportState, logunit, mainproc, rc)
       enddo
    enddo
  end subroutine dems_init_dfields

  subroutine ModelFinalize(gcomp, rc)
    type(ESMF_GridComp)  :: gcomp
    integer, intent(out) :: rc
    rc = ESMF_SUCCESS
  end subroutine ModelFinalize

#ifdef CESMCOUPLED
end module dems_comp_nuopc
#else
end module cdeps_dems_comp
#endif
