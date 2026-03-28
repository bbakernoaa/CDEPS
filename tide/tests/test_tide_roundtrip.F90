program test_tide_roundtrip
  use tide_mod
  use ESMF
  use pio
  use netcdf
  use shr_kind_mod, only : r8 => shr_kind_r8
  implicit none

  type(tide_type) :: tide
  type(ESMF_Mesh) :: mesh
  type(ESMF_Clock) :: clock
  type(ESMF_Time) :: startTime, stopTime, currTime
  type(ESMF_TimeInterval) :: timeStep
  integer :: rc
  real(r8), pointer :: data_ptr(:,:)
  character(len=256) :: config_file = "test_roundtrip.yaml"
  character(len=256) :: data_file = "test_roundtrip_data.nc"
  integer :: ncid, dimid, varid, cf_rc
  integer :: my_task, n_tasks, comm
  type(ESMF_VM) :: vm
  real(r8) :: so2_flux(1)

  call ESMF_Initialize(rc=rc)
  if (rc /= ESMF_SUCCESS) stop 1

  call ESMF_VMGetCurrent(vm, rc=rc)
  call ESMF_VMGet(vm, localPet=my_task, petCount=n_tasks, mpiCommunicator=comm, rc=rc)

  ! Only task 0 writes the data file
  if (my_task == 0) then
    ! Create dummy data file
    cf_rc = nf90_create(trim(data_file), NF90_CLOBBER, ncid)
    cf_rc = nf90_put_att(ncid, NF90_GLOBAL, 'Conventions', 'CF-1.8')
    cf_rc = nf90_def_dim(ncid, 'time', NF90_UNLIMITED, dimid)
    cf_rc = nf90_def_var(ncid, 'time', NF90_DOUBLE, [dimid], varid)
    cf_rc = nf90_put_att(ncid, varid, 'units', 'days since 2000-01-01 00:00:00')
    cf_rc = nf90_put_att(ncid, varid, 'calendar', 'noleap')

    cf_rc = nf90_def_var(ncid, 'so2_flux_var', NF90_DOUBLE, [dimid], varid)
    cf_rc = nf90_put_att(ncid, varid, 'units', 'kg m-2 s-1')
    cf_rc = nf90_put_att(ncid, varid, 'standard_name', 'so2_flux_std')
    cf_rc = nf90_enddef(ncid)

    ! Write 2 time steps:
    cf_rc = nf90_inq_varid(ncid, 'time', varid)
    cf_rc = nf90_put_var(ncid, varid, [0.0d0, 1.0d0])

    cf_rc = nf90_inq_varid(ncid, 'so2_flux_var', varid)
    cf_rc = nf90_put_var(ncid, varid, [1.0d0, 2.0d0])
    cf_rc = nf90_close(ncid)

    ! Create yaml config
    open(unit=99, file=trim(config_file), status='replace')
    write(99, '(a)') 'streams:'
    write(99, '(a)') '  - name: stream1'
    write(99, '(a)') '    tax_mode: "cycle"'
    write(99, '(a)') '    time_interp: "linear"'
    write(99, '(a)') '    map_algo: "none"'
    write(99, '(a)') '    year_first: 2000'
    write(99, '(a)') '    year_last: 2000'
    write(99, '(a)') '    year_align: 2000'
    write(99, '(a)') '    cf_detection: "auto"'
    write(99, '(a)') '    input_files:'
    write(99, '(a)') '      - "test_roundtrip_data.nc"'
    write(99, '(a)') '    field_maps:'
    write(99, '(a)') '      - { file_var: "so2_flux_var", model_var: "so2_flux" }'
    close(99)
  end if

  call ESMF_VMBroadcast(vm, config_file, 256, 0, rc=rc)

  ! Create a dummy mesh with 1 element (4 nodes)
  mesh = ESMF_MeshCreate(parametricDim=2, spatialDim=2, rc=rc)
  call ESMF_MeshAddNodes(mesh, nodeCount=4, nodeIds=[1,2,3,4], &
       nodeCoords=[0.0d0, 0.0d0, 1.0d0, 0.0d0, 1.0d0, 1.0d0, 0.0d0, 1.0d0], &
       nodeOwners=[0,0,0,0], rc=rc)
  call ESMF_MeshAddElements(mesh, elementCount=1, elementIds=[1], &
       elementTypes=[ESMF_MESHELEMTYPE_QUAD], elementConn=[1,2,3,4], rc=rc)

  call ESMF_TimeSet(startTime, yy=2000, mm=1, dd=1, s=0, rc=rc)
  call ESMF_TimeSet(stopTime, yy=2000, mm=1, dd=2, s=0, rc=rc)
  call ESMF_TimeIntervalSet(timeStep, d=1, rc=rc)
  clock = ESMF_ClockCreate(timeStep, startTime, stopTime=stopTime, rc=rc)

  ! Verify init
  call tide_init(tide, config_yaml=config_file, model_mesh=mesh, clock=clock, rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "TIDE API: tide_init failed."
     stop 1
  endif

  ! Verify advance
  call ESMF_ClockAdvance(clock, rc=rc)
  call tide_advance(tide, clock, rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "TIDE API: tide_advance failed."
     stop 1
  endif

  ! Verify ptr get
  call tide_get_ptr(tide, "so2_flux", data_ptr, rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "TIDE API: tide_get_ptr failed."
     stop 1
  endif

  print *, "Extracted so2_flux = ", data_ptr(1,1)

  call tide_finalize(tide, rc)

  if (my_task == 0) then
     open(unit=99, file=trim(data_file), status='old', iostat=rc)
     if (rc == 0) close(99, status='delete')
     open(unit=99, file=trim(config_file), status='old', iostat=rc)
     if (rc == 0) close(99, status='delete')
  endif

  call ESMF_MeshDestroy(mesh, rc=rc)
  call ESMF_ClockDestroy(clock, rc=rc)
  call ESMF_Finalize(rc=rc)

  print *, "TIDE API: Roundtrip test passed."
end program test_tide_roundtrip
