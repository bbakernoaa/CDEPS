import re

# Read original from backup if it's cleaner, but it also has duplication
with open('dshr_strdata_mod.F90.bak', 'r') as f:
    lines = f.readlines()

# The goal is to strip EVERYTHING from the first occurrence of
# 'subroutine shr_strdata_create_mesh_from_file' or 'subroutine shr_cal_getdayofweek'
# until the end of the module.

cut_off = -1
for i, line in enumerate(lines):
    if 'subroutine shr_strdata_create_mesh_from_file' in line or 'subroutine shr_cal_getdayofweek' in line:
        cut_off = i
        break

if cut_off == -1:
    # Try finding the end of the last "good" subroutine
    for i, line in enumerate(lines):
        if 'end subroutine shr_strdata_get_stream_pointer_2d' in line:
            cut_off = i + 1
            break

new_lines = lines[:cut_off]

new_subroutines = """
  subroutine shr_strdata_create_mesh_from_file(sdat, ns, filename, mesh, rc)
    use ESMF, only : ESMF_GridGet
    type(shr_strdata_type) , intent(inout) :: sdat
    integer                , intent(in)    :: ns
    character(len=*)       , intent(in)    :: filename
    type(ESMF_Mesh)        , intent(out)   :: mesh
    integer                , intent(out)   :: rc

    type(ESMF_VM)           :: vm
    type(file_desc_t)       :: pioid
    type(var_desc_t)        :: varid_lat, varid_lon
    integer                 :: dimid_lat, dimid_lon
    integer                 :: nlat, nlon
    real(r8), allocatable   :: lat(:), lon(:)
    integer                 :: rcode
    type(ESMF_Grid)         :: grid
    integer                 :: maxIndex(2)
    character(CS)           :: lat_name, lon_name
    integer                 :: old_handle
    real(r8), pointer       :: grid_lon(:,:), grid_lat(:,:)
    integer                 :: i, j
    integer, allocatable    :: dimids(:)
    integer                 :: ndims
    integer                 :: is(2), ie(2)
    real(r8)                :: minCoord(2), maxCoord(2)

    rc = ESMF_SUCCESS
    call ESMF_VMGetCurrent(vm, rc=rc)

    ! Open the file
    rcode = pio_openfile(sdat%pio_subsystem, pioid, sdat%io_type, trim(filename), pio_nowrite)

    ! Try to find lat/lon variable names
    lat_name = 'lat'
    call pio_seterrorhandling(pioid, PIO_BCAST_ERROR, old_handle)
    rcode = pio_inq_varid(pioid, 'lat', varid_lat)
    if (rcode /= PIO_NOERR) then
       rcode = pio_inq_varid(pioid, 'latitude', varid_lat)
       if (rcode == PIO_NOERR) lat_name = 'latitude'
    endif

    lon_name = 'lon'
    rcode = pio_inq_varid(pioid, 'lon', varid_lon)
    if (rcode /= PIO_NOERR) then
       rcode = pio_inq_varid(pioid, 'longitude', varid_lon)
       if (rcode == PIO_NOERR) lon_name = 'longitude'
    endif
    call pio_seterrorhandling(pioid, old_handle)

    ! Find dimension IDs for lat/lon
    call pio_inq_varndims(pioid, varid_lat, ndims)
    allocate(dimids(ndims))
    call pio_inq_vardimid(pioid, varid_lat, dimids)
    dimid_lat = dimids(1)
    deallocate(dimids)
    rcode = pio_inq_dimlen(pioid, dimid_lat, nlat)

    call pio_inq_varndims(pioid, varid_lon, ndims)
    allocate(dimids(ndims))
    call pio_inq_vardimid(pioid, varid_lon, dimids)
    dimid_lon = dimids(1)
    deallocate(dimids)
    rcode = pio_inq_dimlen(pioid, dimid_lon, nlon)

    allocate(lat(nlat), lon(nlon))
    rcode = pio_get_var(pioid, varid_lat, lat)
    rcode = pio_get_var(pioid, varid_lon, lon)
    call pio_closefile(pioid)

    ! Create Grid from lat/lon
    maxIndex = (/nlon, nlat/)
    minCoord = (/ minval(lon), minval(lat) /)
    maxCoord = (/ maxval(lon), maxval(lat) /)

    grid = ESMF_GridCreateNoPeriDimUfrm(maxIndex=maxIndex, &
           minCornerCoord=minCoord, maxCornerCoord=maxCoord, &
           coordSys=ESMF_COORDSYS_SPH_DEG, &
           staggerloclist=(/ESMF_STAGGERLOC_CENTER/), &
           indexflag=ESMF_INDEX_GLOBAL, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    ! Set Grid coordinates
    call ESMF_GridGetCoord(grid, coordDim=1, staggerloc=ESMF_STAGGERLOC_CENTER, farrayPtr=grid_lon, rc=rc)
    call ESMF_GridGetCoord(grid, coordDim=2, staggerloc=ESMF_STAGGERLOC_CENTER, farrayPtr=grid_lat, rc=rc)
    call ESMF_GridGet(grid, staggerloc=ESMF_STAGGERLOC_CENTER, localDe=0, exclusiveLBound=is, exclusiveUBound=ie, rc=rc)

    do j = 1, ie(2)-is(2)+1
       do i = 1, ie(1)-is(1)+1
          grid_lon(i,j) = lon(i + is(1) - 1)
          grid_lat(i,j) = lat(j + is(2) - 1)
       end do
    end do

    ! Convert Grid to Mesh
    mesh = ESMF_MeshCreate(grid, rc=rc)
    if (ChkErr(rc,__LINE__,u_FILE_u)) return

    deallocate(lat, lon)
  end subroutine shr_strdata_create_mesh_from_file

  subroutine shr_cal_getdayofweek(year, month, day, dow)
    integer, intent(in)  :: year, month, day
    integer, intent(out) :: dow

    integer :: a, y, m

    a = (14 - month) / 12
    y = year - a
    m = month + 12 * a - 2

    ! Zeller's congruence algorithm
    ! Returns 0=Sunday, 1=Monday, ..., 6=Saturday
    dow = modulo(day + y + y/4 - y/100 + y/400 + (31*m)/12, 7)
  end subroutine shr_cal_getdayofweek

end module dshr_strdata_mod
"""

content = "".join(new_lines) + new_subroutines

# Fix up use statements
content = content.replace(
    '  use pio              , only : pio_double, pio_real, pio_int, pio_offset_kind, pio_get_var',
    '  use pio              , only : pio_double, pio_real, pio_int, pio_offset_kind, pio_get_var, pio_inquire_variable'
)

content = content.replace(
    '  use ESMF             , only : ESMF_ClockGet, operator(-), operator(==), ESMF_CALKIND_NOLEAP',
    '  use ESMF             , only : ESMF_ClockGet, operator(-), operator(==), ESMF_CALKIND_NOLEAP, &\n'
    '                             ESMF_Grid, ESMF_GridCreateNoPeriDimUfrm, ESMF_GridGetCoord, ESMF_GridGet, &\n'
    '                             ESMF_INDEX_GLOBAL, ESMF_COORDSYS_SPH_DEG'
)

# Fix private list
content = content.replace(
    '  private :: shr_strdata_readLBUB',
    '  private :: shr_strdata_readLBUB, shr_strdata_create_mesh_from_file'
)

with open('streams/dshr_strdata_mod.F90', 'w') as f:
    f.write(content)
