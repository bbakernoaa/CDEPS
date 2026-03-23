program test_tide
  use esmf
  use tide_mod
  use dshr_strdata_mod, only: shr_strdata_type
  implicit none
  type(ESMF_TimeInterval) :: tStep
  type(ESMF_Time) :: sTime

  integer :: rc
  type(shr_strdata_type) :: sdat
  type(ESMF_Clock) :: model_clock
  type(ESMF_Mesh) :: model_mesh
  integer :: logunit = 6

  call ESMF_Initialize(defaultCalKind=ESMF_CALKIND_GREGORIAN, rc=rc)
  print *, "Error code: ", rc
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_Initialize failed"
     stop 1
  endif

  call ESMF_TimeIntervalSet(tStep, h=1, rc=rc)
  if (rc /= ESMF_SUCCESS) stop 2

  call ESMF_TimeSet(sTime, yy=2000, mm=1, dd=1, rc=rc)
  if (rc /= ESMF_SUCCESS) stop 3

  model_clock = ESMF_ClockCreate(timeStep=tStep, startTime=sTime, rc=rc)
  print *, "Error code: ", rc
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_ClockCreate failed"
     stop 4
  endif

  model_mesh = ESMF_MeshCreate(spatialDim=2, parametricDim=2, rc=rc)
  ! call ESMF_MeshAddNodes(model_mesh, nodeIds=(/1,2,3,4/), &
       ! nodeCoords=(/0.0_8,0.0_8, 1.0_8,0.0_8, 1.0_8,1.0_8, 0.0_8,1.0_8/), rc=rc)
  ! call ESMF_MeshAddElements(model_mesh, elementIds=(/1/), &
       ! elementTypes=(/ESMF_MESHELEMTYPE_QUAD/), elementConn=(/1,2,3,4/), rc=rc)
  print *, "Error code: ", rc
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_MeshCreate failed"
     stop 5
  endif

  ! call tide_init(sdat, 0, logunit, "TIDE_TEST", rc, &
  !      model_clock, model_mesh, &
  !      "none", "lat", "bilinear", &
  !      (/"test_stream.nc"/), (/"data"/), (/"temperature"/), &
  !      2000, 2000, 2000, &
  !      0, "extend", 1.0_8, "nearest", &
  !      stream_name="test_stream")
  !
  ! print *, "Error code: ", rc
  ! if (rc /= ESMF_SUCCESS) then
  !    print *, "tide_init failed"
  !    stop 6
  ! endif

  print *, "TIDE successfully initialized!"

  call ESMF_Finalize(rc=rc)

end program test_tide