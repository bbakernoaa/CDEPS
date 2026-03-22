module tide_yaml_mod
  use, intrinsic :: iso_c_binding
  implicit none

  type, bind(c) :: tide_stream_config_t
    type(c_ptr) :: name
    type(c_ptr) :: mesh_file
    type(c_ptr) :: lev_dimname
    type(c_ptr) :: tax_mode
    type(c_ptr) :: time_interp
    type(c_ptr) :: map_algo
    type(c_ptr) :: read_mode
    real(c_double) :: dt_limit
    integer(c_int) :: year_first
    integer(c_int) :: year_last
    integer(c_int) :: year_align
    integer(c_int) :: offset
    type(c_ptr) :: input_files
    integer(c_int) :: num_files
    type(c_ptr) :: file_vars
    type(c_ptr) :: model_vars
    integer(c_int) :: num_fields
  end type tide_stream_config_t

  type, bind(c) :: tide_config_t
    type(c_ptr) :: streams
    integer(c_int) :: num_streams
  end type tide_config_t

  interface
    function tide_parse_yaml(filename) bind(c, name="tide_parse_yaml")
      use, intrinsic :: iso_c_binding
      type(c_ptr), value :: filename
      type(c_ptr) :: tide_parse_yaml
    end function tide_parse_yaml

    subroutine tide_free_config(cfg) bind(c, name="tide_free_config")
      use, intrinsic :: iso_c_binding
      type(c_ptr), value :: cfg
    end subroutine tide_free_config
  end interface

contains

  ! Helper to convert C strings to Fortran strings
  subroutine c_to_f_string(cptr, fstr)
    type(c_ptr), intent(in) :: cptr
    character(len=*), intent(out) :: fstr
    character(kind=c_char), pointer :: p(:)
    integer :: i, n

    if (.not. c_associated(cptr)) then
      fstr = ' '
      return
    end if

    n = len(fstr)
    call c_f_pointer(cptr, p, [n])
    fstr = ' '
    do i = 1, n
      if (p(i) == c_null_char) exit
      fstr(i:i) = p(i)
    end do
  end subroutine c_to_f_string

end module tide_yaml_mod
