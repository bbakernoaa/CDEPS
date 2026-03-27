program test_pio_open
  use pio
  implicit none
  integer :: io_type = PIO_IOTYPE_NETCDF
  integer :: pio_rc
  type(iosystem_desc_t) :: pio_subsystem
  type(file_desc_t) :: pio_file
  character(len=64) :: filename = "test.nc"

  pio_rc = pio_openfile(pio_subsystem, pio_file, io_type, trim(filename), pio_nowrite)
end program
