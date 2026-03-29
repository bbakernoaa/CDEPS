program test_parse
  use shr_string_mod, only : shr_string_parseCFtunit
  use shr_kind_mod, only : SHR_KIND_IN, SHR_KIND_R8
  implicit none

  character(len=256) :: string, unit
  integer(SHR_KIND_IN) :: bdate
  real(SHR_KIND_R8) :: bsec

  string = "s since 2000-01-01 00:00:00"
  call shr_string_parseCFtunit(string, unit, bdate, bsec)
  print *, "unit = ", trim(unit), " bdate = ", bdate, " bsec = ", bsec

  string = "d since 2000-01-01 00:00:00"
  call shr_string_parseCFtunit(string, unit, bdate, bsec)
  print *, "unit = ", trim(unit), " bdate = ", bdate, " bsec = ", bsec

  string = "hrs since 2000-01-01 00:00:00"
  call shr_string_parseCFtunit(string, unit, bdate, bsec)
  print *, "unit = ", trim(unit), " bdate = ", bdate, " bsec = ", bsec

end program test_parse
