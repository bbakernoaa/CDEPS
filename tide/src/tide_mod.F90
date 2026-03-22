module tide_mod
  use tide_yaml_mod
  use dshr_strdata_mod
  use ESMF
  use, intrinsic :: iso_c_binding
  use shr_kind_mod, only : r8 => shr_kind_r8, cl => shr_kind_cl, cs => shr_kind_cs
  implicit none

  type tide_type
    type(shr_strdata_type) :: sdat
  end type tide_type

contains

  subroutine tide_init(tide, config_yaml, model_mesh, clock, rc)
    use dshr_strdata_mod, only : shr_strdata_init_from_inline
    type(tide_type), intent(inout) :: tide
    character(len=*), intent(in) :: config_yaml
    type(ESMF_Mesh), intent(in) :: model_mesh
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    type(c_ptr) :: c_cfg_ptr
    type(tide_config_t), pointer :: cfg
    type(tide_stream_config_t), pointer :: s_cfg_ptr(:)
    integer :: i, j
    character(len=1024) :: c_str
    character(kind=c_char), target :: c_config_yaml(len(trim(config_yaml))+1)
    character(len=cl), allocatable :: file_names(:)
    character(len=cl), allocatable :: fld_list_file(:)
    character(len=cl), allocatable :: fld_list_model(:)
    type(c_ptr), pointer :: input_files_ptr(:)
    type(c_ptr), pointer :: file_vars_ptr(:)
    type(c_ptr), pointer :: model_vars_ptr(:)
    integer :: my_task
    type(ESMF_VM) :: vm
    character(len=cl) :: mesh_file, tax_mode, time_interp, map_algo

    rc = ESMF_SUCCESS

    ! Parse YAML
    do i = 1, len(trim(config_yaml))
      c_config_yaml(i) = config_yaml(i:i)
    end do
    c_config_yaml(len(trim(config_yaml))+1) = c_null_char

    c_cfg_ptr = tide_parse_yaml(c_loc(c_config_yaml))
    if (.not. c_associated(c_cfg_ptr)) then
      rc = ESMF_FAILURE
      return
    end if
    call c_f_pointer(c_cfg_ptr, cfg)

    if (cfg%num_streams < 1) return
    call c_f_pointer(cfg%streams, s_cfg_ptr, [cfg%num_streams])

    call ESMF_VMGetCurrent(vm, rc=rc)
    call ESMF_VMGet(vm, localPet=my_task, rc=rc)

    ! For now, we only support 1 stream in the simplified TIDE API
    i = 1
    allocate(file_names(s_cfg_ptr(i)%num_files))
    call c_f_pointer(s_cfg_ptr(i)%input_files, input_files_ptr, [s_cfg_ptr(i)%num_files])
    do j = 1, s_cfg_ptr(i)%num_files
      call c_to_f_string(input_files_ptr(j), c_str)
      file_names(j) = trim(c_str)
    end do

    allocate(fld_list_file(s_cfg_ptr(i)%num_fields))
    allocate(fld_list_model(s_cfg_ptr(i)%num_fields))
    call c_f_pointer(s_cfg_ptr(i)%file_vars, file_vars_ptr, [s_cfg_ptr(i)%num_fields])
    call c_f_pointer(s_cfg_ptr(i)%model_vars, model_vars_ptr, [s_cfg_ptr(i)%num_fields])
    do j = 1, s_cfg_ptr(i)%num_fields
      call c_to_f_string(file_vars_ptr(j), c_str)
      fld_list_file(j) = trim(c_str)
      call c_to_f_string(model_vars_ptr(j), c_str)
      fld_list_model(j) = trim(c_str)
    end do

    call c_to_f_string(s_cfg_ptr(i)%mesh_file, mesh_file)
    call c_to_f_string(s_cfg_ptr(i)%tax_mode, tax_mode)
    call c_to_f_string(s_cfg_ptr(i)%time_interp, time_interp)
    call c_to_f_string(s_cfg_ptr(i)%map_algo, map_algo)

    ! Initialize TIDE core
    call shr_strdata_init_from_inline(tide%sdat, my_task, 6, "TIDE", &
         clock, model_mesh, trim(mesh_file), "null", trim(map_algo), &
         file_names, fld_list_file, fld_list_model, &
         int(s_cfg_ptr(i)%year_first), int(s_cfg_ptr(i)%year_last), int(s_cfg_ptr(i)%year_align), &
         int(s_cfg_ptr(i)%offset), trim(tax_mode), real(s_cfg_ptr(i)%dt_limit, r8), trim(time_interp), &
         rc=rc)

    call tide_free_config(c_cfg_ptr)

  end subroutine tide_init

  subroutine tide_advance(tide, clock, rc)
    use shr_cal_mod, only : shr_cal_date2ymd
    type(tide_type), intent(inout) :: tide
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    type(ESMF_Time) :: currTime
    integer :: yy, mm, dd, tod, ymd

    call ESMF_ClockGet(clock, currTime=currTime, rc=rc)
    call ESMF_TimeGet(currTime, yy=yy, mm=mm, dd=dd, s=tod, rc=rc)
    call shr_cal_ymd2date(yy, mm, dd, ymd)

    call shr_strdata_advance(tide%sdat, ymd, tod, 6, "TIDE", rc=rc)
  end subroutine tide_advance

  subroutine tide_get_ptr(tide, field_name, ptr, rc)
    type(tide_type), intent(in) :: tide
    character(len=*), intent(in) :: field_name
    real(r8), pointer :: ptr(:,:)
    integer, intent(out) :: rc

    call shr_strdata_get_stream_pointer(tide%sdat, field_name, ptr, rc)
  end subroutine tide_get_ptr

end module tide_mod
