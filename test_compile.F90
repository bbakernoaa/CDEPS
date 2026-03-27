program test_compile
  use pio, only: iosystem_desc_t, file_desc_t, pio_openfile, pio_nowrite
  implicit none
  type(iosystem_desc_t) :: pio_subsystem
  type(file_desc_t) :: pio_file
  integer :: pio_rc
  character(len=256) :: filename = "test.nc"
  integer :: io_type = 1

  pio_rc = pio_openfile(pio_subsystem, pio_file, io_type, trim(filename), pio_nowrite)
end program test_compile
