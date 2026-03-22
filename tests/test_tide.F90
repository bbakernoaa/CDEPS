program test_tide
  use esmf
  use tide_mod
  implicit none

  integer :: rc
  type(shr_strdata_type) :: sdat
  type(ESMF_Clock) :: model_clock
  type(ESMF_Mesh) :: model_mesh
  integer :: logunit = 6

  call ESMF_Initialize(rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_Initialize failed"
     stop 1
  endif

  model_clock = ESMF_ClockCreate(rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_ClockCreate failed"
     stop 1
  endif

  model_mesh = ESMF_MeshCreate(spatialDim=2, parametricDim=2, rc=rc)
  if (rc /= ESMF_SUCCESS) then
     print *, "ESMF_MeshCreate failed"
     stop 1
  endif

  call tide_init(sdat, 0, logunit, "TIDE_TEST", rc, &
       model_clock, model_mesh, &
       "none", "none", "none", &
       (/"none"/), (/"none"/), (/"none"/), &
       2000, 2000, 2000, &
       0, "extend", 1.0_8, "nearest", &
       stream_name="test_stream")

  print *, "TIDE successfully initialized!"

  call ESMF_Finalize(rc=rc)

end program test_tide