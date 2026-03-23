add_executable(test_tide test_tide.F90)

target_include_directories(test_tide PRIVATE ${ESMF_F90COMPILEPATHS} ${CMAKE_BINARY_DIR}/streams)
target_include_directories(test_tide PRIVATE ${PIO_Fortran_INCLUDE_DIR})

target_link_libraries(test_tide streams cdeps_share)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${ESMF_F90ESMFLINKRPATHS}")
string(REPLACE " " ";" ESMF_F90ESMFLINKLIBS_LIST "${ESMF_F90ESMFLINKLIBS}")


target_link_directories(test_tide PRIVATE "/opt/views/view/lib")
target_link_libraries(test_tide esmf piof pioc netcdff netcdf)
add_test(NAME test_tide COMMAND test_tide)
