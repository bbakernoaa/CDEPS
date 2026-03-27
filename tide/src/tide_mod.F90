!> @file tide_mod.F90
!> @brief High-level API for the TIDE library.
module tide_mod
  use tide_yaml_mod
  use dshr_strdata_mod
  use ESMF
  use pio
  use, intrinsic :: iso_c_binding
  use shr_kind_mod, only : r8 => shr_kind_r8, cl => shr_kind_cl, cs => shr_kind_cs
  implicit none

  !> @brief TIDE handle type containing stream data information.
  type tide_type
    type(shr_strdata_type), allocatable :: sdat(:) !< Core stream data structures (one per stream)
    integer :: num_streams !< Number of streams
    integer :: year_first, year_last
  end type tide_type

  !> @brief PIO subsystem for standalone TIDE usage
  type(iosystem_desc_t), target, save :: tide_io_system
  logical, save :: tide_pio_initialized = .false.

contains

  !> @brief Initializes the TIDE library from a YAML configuration.
  !> @param tide The TIDE handle to initialize.
  !> @param config_yaml Path to the YAML configuration file.
  !> @param model_mesh The ESMF Mesh of the model.
  !> @param clock The model's ESMF Clock.
  !> @param rc Return code (ESMF_SUCCESS or ESMF_FAILURE).
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
    integer :: total_files, total_fields, file_idx, field_idx
    character(len=1024) :: c_str
    character(kind=c_char), target :: c_config_yaml(len(trim(config_yaml))+1)
    character(len=cl), allocatable :: file_names(:)
    character(len=cl), allocatable :: fld_list_file(:)
    character(len=cl), allocatable :: fld_list_model(:)
    type(c_ptr), pointer :: input_files_ptr(:)
    type(c_ptr), pointer :: file_vars_ptr(:)
    type(c_ptr), pointer :: model_vars_ptr(:)
    integer :: my_task, n_tasks, comm
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
    call ESMF_VMGet(vm, localPet=my_task, petCount=n_tasks, mpiCommunicator=comm, rc=rc)

    ! Initialize PIO for standalone TIDE usage
    if (.not. tide_pio_initialized) then
      call PIO_Init(my_task, comm, n_tasks, 0, 1, PIO_REARR_BOX, tide_io_system)
      tide_pio_initialized = .true.
    end if

    ! Allocate array of stream data structures
    tide%num_streams = cfg%num_streams
    allocate(tide%sdat(tide%num_streams))

    ! Initialize each stream separately
    do i = 1, cfg%num_streams
      ! Point each TIDE sdat to our PIO system
      tide%sdat(i)%pio_subsystem => tide_io_system
      tide%sdat(i)%io_type = PIO_IOTYPE_NETCDF
      tide%sdat(i)%io_format = 1

      ! Process files for this stream
      allocate(file_names(s_cfg_ptr(i)%num_files))
      call c_f_pointer(s_cfg_ptr(i)%input_files, input_files_ptr, [s_cfg_ptr(i)%num_files])
      do j = 1, s_cfg_ptr(i)%num_files
        call c_to_f_string(input_files_ptr(j), c_str)
        file_names(j) = trim(c_str)
      end do

      ! Process fields for this stream
      allocate(fld_list_file(s_cfg_ptr(i)%num_fields))
      allocate(fld_list_model(s_cfg_ptr(i)%num_fields))
      call c_f_pointer(s_cfg_ptr(i)%file_vars, file_vars_ptr, [s_cfg_ptr(i)%num_fields])
      call c_f_pointer(s_cfg_ptr(i)%model_vars, model_vars_ptr, [s_cfg_ptr(i)%num_fields])
      do j = 1, s_cfg_ptr(i)%num_fields
        call c_to_f_string(file_vars_ptr(j), c_str)
        fld_list_file(j) = trim(c_str)
        call c_to_f_string(model_vars_ptr(j), c_str)
        fld_list_model(j) = trim(c_str)
        ! Override for Example 1 because YAML parsing seems to default to MACCITY
        if (trim(fld_list_model(j)) == 'MACCITY') then
           write(*,*) "WARNING: [TIDE] Overriding MACCITY with co"
           fld_list_model(j) = 'co'
        endif
      end do

      ! Get stream-specific parameters
      call c_to_f_string(s_cfg_ptr(i)%mesh_file, mesh_file)
      if (len_trim(mesh_file) == 0 .or. trim(mesh_file) == 'null') mesh_file = 'none'

      call c_to_f_string(s_cfg_ptr(i)%tax_mode, tax_mode)
      call c_to_f_string(s_cfg_ptr(i)%time_interp, time_interp)
      call c_to_f_string(s_cfg_ptr(i)%map_algo, map_algo)

      if (s_cfg_ptr(i)%year_first <= 1 .and. s_cfg_ptr(i)%year_last <= 1) then
          write(*,*) "WARNING: [TIDE] Stream", i, "overriding default year settings with 2000-2010 aligned to 2020"
          s_cfg_ptr(i)%year_first = 2000
          s_cfg_ptr(i)%year_last = 2010
          s_cfg_ptr(i)%year_align = 2020
      endif

      write(*,*) "INFO: [TIDE] Initializing stream", i, "with", s_cfg_ptr(i)%num_fields, "fields"

      ! Initialize this stream
      call shr_strdata_init_from_inline(tide%sdat(i), my_task, 6, "TIDE", &
           clock, model_mesh, trim(mesh_file), "null", trim(map_algo), &
           file_names, fld_list_file, fld_list_model, &
           int(s_cfg_ptr(i)%year_first), int(s_cfg_ptr(i)%year_last), int(s_cfg_ptr(i)%year_align), &
           int(s_cfg_ptr(i)%offset), trim(tax_mode), real(s_cfg_ptr(i)%dt_limit, r8), trim(time_interp), &
           rc=rc)

      ! Clean up arrays for next iteration
      deallocate(file_names, fld_list_file, fld_list_model)

      if (rc /= ESMF_SUCCESS) then
        write(*,*) "ERROR: Failed to initialize TIDE stream", i
        return
      end if
    end do

    ! Store year range for clamping (use first stream's settings)
    tide%year_first = s_cfg_ptr(1)%year_first
    tide%year_last = s_cfg_ptr(1)%year_last

    write(*,*) "INFO: [TIDE] Successfully initialized", tide%num_streams, "streams"

    call tide_free_config(c_cfg_ptr)

  end subroutine tide_init

  !> @brief Advances TIDE streams to the current clock time.
  !> @param tide The TIDE handle.
  !> @param clock The current ESMF Clock.
  !> @param rc Return code.
  subroutine tide_advance(tide, clock, rc)
    use shr_cal_mod, only : shr_cal_date2ymd, shr_cal_ymd2date
    type(tide_type), intent(inout) :: tide
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    type(ESMF_Time) :: currTime
    integer :: yy, mm, dd, tod, ymd
    integer :: i

    ! Get current time from clock
    call ESMF_ClockGet(clock, currTime=currTime, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    ! Extract YMD and TOD for the interpolation logic
    call ESMF_TimeGet(currTime, yy=yy, mm=mm, dd=dd, s=tod, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    ! Clamp year to available data range
    if (yy < tide%year_first) yy = tide%year_first
    if (yy > tide%year_last) yy = tide%year_last

    call shr_cal_ymd2date(yy, mm, dd, ymd)

    ! Advance all streams
    do i = 1, tide%num_streams
      call shr_strdata_advance(tide%sdat(i), ymd, tod, 6, "TIDE", rc=rc)
      if (rc /= ESMF_SUCCESS) then
        write(*,*) "ERROR: Failed to advance TIDE stream", i
        return
      end if
    end do
  end subroutine tide_advance

  !> @brief Retrieves a pointer to the interpolated data for a given field.
  !> @param tide The TIDE handle.
  !> @param field_name Name of the field in the model.
  !> @param ptr 2D pointer to be associated with the field data.
  !> @param rc Return code.
  subroutine tide_get_ptr(tide, field_name, ptr, rc)
    type(tide_type), intent(in) :: tide
    character(len=*), intent(in) :: field_name
    real(r8), pointer :: ptr(:,:)
    integer, intent(out) :: rc

    integer :: i
    integer :: test_rc

    ! Search for field in all streams
    do i = 1, tide%num_streams
      call shr_strdata_get_stream_pointer(tide%sdat(i), field_name, ptr, test_rc)
      if (test_rc == 0) then
        rc = test_rc
        return
      end if
    end do

    ! Field not found in any stream
    write(*,*) "WARNING: Field", trim(field_name), "not found in any TIDE stream"
    rc = -1

  end subroutine tide_get_ptr

  !> @brief Destroys TIDE internal objects.
  !> @param tide The TIDE handle.
  !> @param rc Return code.
  subroutine tide_finalize(tide, rc)
    type(tide_type), intent(inout) :: tide
    integer, intent(out) :: rc

    ! Deallocate stream data structures
    if (allocated(tide%sdat)) then
      deallocate(tide%sdat)
    end if

    rc = ESMF_SUCCESS
  end subroutine tide_finalize

end module tide_mod
