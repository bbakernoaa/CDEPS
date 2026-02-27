program test_dems_agg
  use ESMF
  use cdeps_dems_comp, only : SetServices
  implicit none

  type(ESMF_GridComp) :: dems_comp
  integer :: rc

  ! This is a structural test that verifies the component can be instantiated.
  ! A full Run test requires a complete ESMF/PIO environment with NetCDF data.
  call ESMF_Initialize(rc=rc)
  if (rc /= ESMF_SUCCESS) stop "ESMF_Initialize failed"

  dems_comp = ESMF_GridCompCreate(name="DEMS", rc=rc)
  if (rc /= ESMF_SUCCESS) stop "ESMF_GridCompCreate failed"

  call ESMF_GridCompSetEntryPoint(dems_comp, ESMF_METHOD_SET_SERVICES, SetServices, rc=rc)
  if (rc /= ESMF_SUCCESS) stop "ESMF_GridCompSetEntryPoint failed"

  call ESMF_GridCompFinalize(dems_comp, rc=rc)
  call ESMF_Finalize(rc=rc)
  print *, "DEMS structural test passed"
end program test_dems_agg
