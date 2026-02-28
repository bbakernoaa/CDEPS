module dems_point_mapper_mod

  use ESMF
  use shr_kind_mod, only : r8=>shr_kind_r8
  use shr_log_mod,  only : shr_log_error

  implicit none
  private

  public :: point_source_type
  public :: point_source_list_type
  public :: dems_point_mapper_read_csv
  public :: dems_point_mapper_map
  public :: dems_point_mapper_to_locstream
  public :: dems_point_mapper_create_field

  type point_source_type
     real(r8) :: lat, lon, alt, flux
     integer  :: i, j, k  ! Mapped grid indices (1-based)
  end type point_source_type

  type point_source_list_type
     type(point_source_type), allocatable :: sources(:)
     integer :: nsources
  end type point_source_list_type

contains

  subroutine dems_point_mapper_read_csv(filename, ps_list, rc)
    character(len=*), intent(in) :: filename
    type(point_source_list_type), intent(out) :: ps_list
    integer, intent(out) :: rc

    integer :: unit, ierr, n
    character(len=256) :: line
    real(r8) :: lat, lon, alt, flux

    rc = ESMF_SUCCESS

    open(newunit=unit, file=trim(filename), status='old', iostat=ierr)
    if (ierr /= 0) then
       rc = ESMF_FAILURE
       return
    endif

    ! Count lines (skip header if any)
    read(unit, *, iostat=ierr) ! Skip header
    n = 0
    do
       read(unit, *, iostat=ierr)
       if (ierr /= 0) exit
       n = n + 1
    end do

    ps_list%nsources = n
    allocate(ps_list%sources(n))

    rewind(unit)
    read(unit, *) ! Skip header
    do ierr = 1, n
       read(unit, *) ps_list%sources(ierr)%lat, &
                      ps_list%sources(ierr)%lon, &
                      ps_list%sources(ierr)%alt, &
                      ps_list%sources(ierr)%flux
    end do

    close(unit)
  end subroutine dems_point_mapper_read_csv

  subroutine dems_point_mapper_map(ps_list, grid, collapsed, field, rc)
    type(point_source_list_type), intent(inout) :: ps_list
    type(ESMF_Grid), intent(in) :: grid
    logical, intent(in) :: collapsed
    type(ESMF_Field), intent(inout) :: field
    integer, intent(out) :: rc

    integer :: i, j, k, p
    integer :: dimCount
    integer :: minIndex(3), maxIndex(3)
    real(r8), pointer :: lon_ptr(:,:,:), lat_ptr(:,:,:), alt_ptr(:,:,:)
    real(r8), pointer :: lon_ptr2(:,:), lat_ptr2(:,:), alt_ptr2(:,:)
    real(r8), pointer :: field_ptr(:,:,:)
    real(r8), pointer :: field_ptr2(:,:)
    logical :: found

    rc = ESMF_SUCCESS

    ! Get grid boundaries
    call ESMF_GridGet(grid, dimCount=dimCount, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    call ESMF_GridGet(grid, minIndex=minIndex, maxIndex=maxIndex, rc=rc)

    if (dimCount == 3) then
       call ESMF_GridGetCoord(grid, coordDim=1, farrayPtr=lon_ptr, rc=rc)
       call ESMF_GridGetCoord(grid, coordDim=2, farrayPtr=lat_ptr, rc=rc)
       call ESMF_GridGetCoord(grid, coordDim=3, farrayPtr=alt_ptr, rc=rc)

       if (collapsed) then
          call ESMF_FieldGet(field, farrayPtr=field_ptr, rc=rc)
          field_ptr = 0.0_r8
       endif

       do p = 1, ps_list%nsources
          call find_nearest_cell_3d(ps_list%sources(p), lon_ptr, lat_ptr, alt_ptr, minIndex, maxIndex, &
               ps_list%sources(p)%i, ps_list%sources(p)%j, ps_list%sources(p)%k)

          if (collapsed) then
             i = ps_list%sources(p)%i
             j = ps_list%sources(p)%j
             k = ps_list%sources(p)%k
             field_ptr(i, j, k) = field_ptr(i, j, k) + ps_list%sources(p)%flux
          endif
       end do
    else
       call ESMF_GridGetCoord(grid, coordDim=1, farrayPtr=lon_ptr2, rc=rc)
       call ESMF_GridGetCoord(grid, coordDim=2, farrayPtr=lat_ptr2, rc=rc)

       if (collapsed) then
          call ESMF_FieldGet(field, farrayPtr=field_ptr2, rc=rc)
          field_ptr2 = 0.0_r8
       endif

       do p = 1, ps_list%nsources
          call find_nearest_cell_2d(ps_list%sources(p), lon_ptr2, lat_ptr2, minIndex, maxIndex, &
               ps_list%sources(p)%i, ps_list%sources(p)%j)
          ps_list%sources(p)%k = 1

          if (collapsed) then
             i = ps_list%sources(p)%i
             j = ps_list%sources(p)%j
             field_ptr2(i, j) = field_ptr2(i, j) + ps_list%sources(p)%flux
          endif
       end do
    endif

  end subroutine dems_point_mapper_map

  subroutine dems_point_mapper_to_locstream(ps_list, lstream, rc)
    type(point_source_list_type), intent(in) :: ps_list
    type(ESMF_LocStream), intent(inout) :: lstream
    integer, intent(out) :: rc

    real(r8), pointer :: lat_ptr(:), lon_ptr(:), alt_ptr(:), flux_ptr(:)
    integer, pointer :: i_ptr(:), j_ptr(:), k_ptr(:)
    integer :: p

    rc = ESMF_SUCCESS

    lstream = ESMF_LocStreamCreate(localCount=ps_list%nsources, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    call ESMF_LocStreamAddKey(lstream, keyName='latitude', rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='longitude', rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='altitude', rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='flux', rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='grid_i', keyTypekind=ESMF_TYPEKIND_I4, rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='grid_j', keyTypekind=ESMF_TYPEKIND_I4, rc=rc)
    call ESMF_LocStreamAddKey(lstream, keyName='grid_k', keyTypekind=ESMF_TYPEKIND_I4, rc=rc)

    call ESMF_LocStreamGetKey(lstream, keyName='latitude', farrayPtr=lat_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='longitude', farrayPtr=lon_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='altitude', farrayPtr=alt_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='flux', farrayPtr=flux_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='grid_i', farrayPtr=i_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='grid_j', farrayPtr=j_ptr, rc=rc)
    call ESMF_LocStreamGetKey(lstream, keyName='grid_k', farrayPtr=k_ptr, rc=rc)

    do p = 1, ps_list%nsources
       lat_ptr(p) = ps_list%sources(p)%lat
       lon_ptr(p) = ps_list%sources(p)%lon
       alt_ptr(p) = ps_list%sources(p)%alt
       flux_ptr(p) = ps_list%sources(p)%flux
       i_ptr(p) = ps_list%sources(p)%i
       j_ptr(p) = ps_list%sources(p)%j
       k_ptr(p) = ps_list%sources(p)%k
    end do
  end subroutine dems_point_mapper_to_locstream

  subroutine dems_point_mapper_create_field(lstream, field, rc)
    type(ESMF_LocStream), intent(in) :: lstream
    type(ESMF_Field), intent(out) :: field
    integer, intent(out) :: rc

    real(r8), pointer :: flux_ptr(:), field_ptr(:)

    rc = ESMF_SUCCESS

    field = ESMF_FieldCreate(lstream, typekind=ESMF_TYPEKIND_R8, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    call ESMF_LocStreamGetKey(lstream, keyName='flux', farrayPtr=flux_ptr, rc=rc)
    call ESMF_FieldGet(field, farrayPtr=field_ptr, rc=rc)

    field_ptr(:) = flux_ptr(:)

  end subroutine dems_point_mapper_create_field

  subroutine find_nearest_cell_3d(source, lon, lat, alt, mins, maxs, best_i, best_j, best_k)
    type(point_source_type), intent(in) :: source
    real(r8), pointer :: lon(:,:,:), lat(:,:,:), alt(:,:,:)
    integer, intent(in) :: mins(3), maxs(3)
    integer, intent(out) :: best_i, best_j, best_k

    real(r8) :: min_dist, dist
    integer :: i, j, k

    min_dist = 1.0e30_r8
    best_i = mins(1); best_j = mins(2); best_k = mins(3)

    do k = mins(3), maxs(3)
       do j = mins(2), maxs(2)
          do i = mins(1), maxs(1)
             dist = (lon(i,j,k) - source%lon)**2 + &
                    (lat(i,j,k) - source%lat)**2 + &
                    (alt(i,j,k) - source%alt)**2
             if (dist < min_dist) then
                min_dist = dist
                best_i = i
                best_j = j
                best_k = k
             endif
          end do
       end do
    end do
  end subroutine find_nearest_cell_3d

  subroutine find_nearest_cell_2d(source, lon, lat, mins, maxs, best_i, best_j)
    type(point_source_type), intent(in) :: source
    real(r8), pointer :: lon(:,:), lat(:,:)
    integer, intent(in) :: mins(3), maxs(3)
    integer, intent(out) :: best_i, best_j

    real(r8) :: min_dist, dist
    integer :: i, j

    min_dist = 1.0e30_r8
    best_i = mins(1); best_j = mins(2)

    do j = mins(2), maxs(2)
       do i = mins(1), maxs(1)
          dist = (lon(i,j) - source%lon)**2 + &
                 (lat(i,j) - source%lat)**2
          if (dist < min_dist) then
             min_dist = dist
             best_i = i
             best_j = j
          endif
       end do
    end do
  end subroutine find_nearest_cell_2d

end module dems_point_mapper_mod
