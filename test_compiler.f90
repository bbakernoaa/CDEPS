program test
  print *, "Compiler check"
end program test
/usr/bin/gfortran test_compiler.f90 -o test_compiler
./test_compiler
