program test_dems_point_mapper
  use ESMF
  use dems_point_mapper_mod
  use shr_kind_mod, only : r8=>shr_kind_r8

  implicit none

  integer :: rc
  type(point_source_list_type) :: ps_list
  type(ESMF_Grid) :: grid
  type(ESMF_Field) :: field
  type(ESMF_DistGrid) :: distgrid
  integer :: i, j, k
  integer :: counts(3)
  real(r8), pointer :: lon_ptr(:,:,:), lat_ptr(:,:,:), alt_ptr(:,:,:)
  real(r8), pointer :: field_ptr(:,:,:)
  integer :: unit

  call ESMF_Initialize(rc=rc)

  ! 1. Create a mock point source CSV
  open(newunit=unit, file='mock_point_sources.csv', status='replace')
  write(unit, *) 'lat,lon,alt,flux'
  write(unit, *) '10.0, 20.0, 500.0, 100.0'
  write(unit, *) '10.1, 20.1, 510.0, 50.0'  ! Should fall in same cell if grid is coarse
  close(unit)

  ! 2. Create a 3D ESMF_Grid
  counts = (/10, 10, 5/)
  distgrid = ESMF_DistGridCreate(minIndex=(/1,1,1/), maxIndex=counts, rc=rc)
  grid = ESMF_GridCreate(distgrid, rc=rc)

  call ESMF_GridAddCoord(grid, rc=rc)
  call ESMF_GridGetCoord(grid, coordDim=1, farrayPtr=lon_ptr, rc=rc)
  call ESMF_GridGetCoord(grid, coordDim=2, farrayPtr=lat_ptr, rc=rc)
  call ESMF_GridGetCoord(grid, coordDim=3, farrayPtr=alt_ptr, rc=rc)

  ! Initialize coords: 0 to 90 for lon/lat, 0 to 5000 for alt
  do k=1, counts(3)
     do j=1, counts(2)
        do i=1, counts(1)
           lon_ptr(i,j,k) = real(i, r8) * 10.0_r8
           lat_ptr(i,j,k) = real(j, r8) * 10.0_r8
           alt_ptr(i,j,k) = real(k, r8) * 1000.0_r8
        end do
     end do
  end do

  ! 3. Create Field
  field = ESMF_FieldCreate(grid, typekind=ESMF_TYPEKIND_R8, rc=rc)

  ! 4. Read CSV
  call dems_point_mapper_read_csv('mock_point_sources.csv', ps_list, rc)
  if (rc /= ESMF_SUCCESS) then
     print *, 'Failed to read CSV'
     stop
  endif

  ! 5. Map Point Sources (Collapsed)
  print *, 'Testing Collapsed Mode...'
  call dems_point_mapper_map(ps_list, grid, .true., field, rc)

  call ESMF_FieldGet(field, farrayPtr=field_ptr, rc=rc)

  ! Expectation:
  ! Source 1 (10, 20, 500) -> closest to lon=10, lat=20, alt=1000?
  ! Actually lon_ptr(i=2,...) = 20, lat_ptr(j=1,...) = 10, alt_ptr(k=1,...) = 1000
  ! Let's check indices in test output.

  print *, 'Source 1 mapped to: ', ps_list%sources(1)%i, ps_list%sources(1)%j, ps_list%sources(1)%k
  print *, 'Source 2 mapped to: ', ps_list%sources(2)%i, ps_list%sources(2)%j, ps_list%sources(2)%k

  if (ps_list%sources(1)%i == ps_list%sources(2)%i .and. &
      ps_list%sources(1)%j == ps_list%sources(2)%j .and. &
      ps_list%sources(1)%k == ps_list%sources(2)%k) then
      print *, 'Both sources fell in same cell. Field value: ', field_ptr(ps_list%sources(1)%i, ps_list%sources(1)%j, ps_list%sources(1)%k)
      if (abs(field_ptr(ps_list%sources(1)%i, ps_list%sources(1)%j, ps_list%sources(1)%k) - 150.0_r8) < 1.0e-5) then
         print *, 'SUCCESS: Collapsed fluxes summed correctly.'
      else
         print *, 'FAILURE: Fluxes did not sum correctly.'
      endif
  endif

  ! 6. Test Uncollapsed (Using LocStream)
  print *, 'Testing Uncollapsed Mode (LocStream)...'
  block
     type(ESMF_LocStream) :: lstream
     type(ESMF_Field) :: ps_field
     real(r8), pointer :: lat_p(:), flux_p(:), ps_f_ptr(:)

     call dems_point_mapper_to_locstream(ps_list, lstream, rc)
     if (rc == ESMF_SUCCESS) then
        call ESMF_LocStreamGetKey(lstream, keyName='latitude', farrayPtr=lat_p, rc=rc)
        call ESMF_LocStreamGetKey(lstream, keyName='flux', farrayPtr=flux_p, rc=rc)
        if (size(lat_p) == 2 .and. abs(flux_p(1) - 100.0_r8) < 1.0e-5 .and. abs(flux_p(2) - 50.0_r8) < 1.0e-5) then
           print *, 'SUCCESS: LocStream contains individual point sources.'
        else
           print *, 'FAILURE: LocStream data incorrect.'
        endif

        call dems_point_mapper_create_field(lstream, ps_field, rc)
        call ESMF_FieldGet(ps_field, farrayPtr=ps_f_ptr, rc=rc)
        if (size(ps_f_ptr) == 2 .and. abs(ps_f_ptr(1) - 100.0_r8) < 1.0e-5) then
           print *, 'SUCCESS: Field on LocStream contains individual point source fluxes.'
        else
           print *, 'FAILURE: Field on LocStream incorrect.'
        endif
     else
        print *, 'FAILURE: Could not create LocStream.'
     endif
  end block

  call ESMF_Finalize(rc=rc)
end program test_dems_point_mapper
