module cdeps_c_wrapper
  use iso_c_binding
  use cdeps_inline_mod
  use ESMF
  implicit none

contains

  subroutine c_cdeps_init(gcomp_ptr, clock_ptr, mesh_ptr, stream_path, rc) bind(C, name="cdeps_init")
    type(c_ptr), value          :: gcomp_ptr, clock_ptr, mesh_ptr
    character(kind=c_char), intent(in) :: stream_path(*)
    integer(c_int), intent(out) :: rc

    type(ESMF_GridComp) :: gcomp
    type(ESMF_Clock)    :: clock
    type(ESMF_Mesh)     :: mesh
    character(len=ESMF_MAXSTR) :: f_stream_path
    integer :: i, f_rc

    ! Convert C string to Fortran string
    f_stream_path = ' '
    do i = 1, ESMF_MAXSTR
       if (stream_path(i) == c_null_char) exit
       f_stream_path(i:i) = stream_path(i)
    end do

    ! Convert c_ptr to ESMF types using transfer
    ! This assumes that ESMF handles are binary-compatible with c_ptr
    ! or at least that the pointer is the first component.
    gcomp = transfer(gcomp_ptr, gcomp)
    clock = transfer(clock_ptr, clock)
    mesh  = transfer(mesh_ptr, mesh)

    call cdeps_inline_init(gcomp, clock, mesh, trim(f_stream_path), f_rc)
    rc = int(f_rc, c_int)
  end subroutine c_cdeps_init

  subroutine c_cdeps_advance(clock_ptr, rc) bind(C, name="cdeps_advance")
    type(c_ptr), value :: clock_ptr
    integer(c_int), intent(out) :: rc

    type(ESMF_Clock) :: clock
    integer :: f_rc

    clock = transfer(clock_ptr, clock)
    call cdeps_inline_advance(clock, f_rc)
    rc = int(f_rc, c_int)
  end subroutine c_cdeps_advance

  subroutine c_cdeps_get_field_ptr(stream_idx, fldname, data_ptr, rc) bind(C, name="cdeps_get_field_ptr")
    integer(c_int), value :: stream_idx
    character(kind=c_char), intent(in) :: fldname(*)
    type(c_ptr), intent(inout) :: data_ptr
    integer(c_int), intent(out) :: rc

    character(len=ESMF_MAXSTR) :: f_fldname
    real(ESMF_KIND_R8), pointer :: f_data_ptr(:)
    integer :: i, f_rc

    ! Convert C string to Fortran string
    f_fldname = ' '
    do i = 1, ESMF_MAXSTR
       if (fldname(i) == c_null_char) exit
       f_fldname(i:i) = fldname(i)
    end do

    call cdeps_get_field_ptr(int(stream_idx), trim(f_fldname), f_data_ptr, f_rc)

    if (f_rc == ESMF_SUCCESS .and. associated(f_data_ptr)) then
       data_ptr = c_loc(f_data_ptr(1))
    else
       data_ptr = c_null_ptr
    endif
    rc = int(f_rc, c_int)
  end subroutine c_cdeps_get_field_ptr

end module cdeps_c_wrapper
