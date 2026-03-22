set(SRCFILES dshr_methods_mod.F90
              dshr_strdata_mod.F90
              dshr_stream_mod.F90
              dshr_tinterp_mod.F90)

add_library(streams ${SRCFILES})

target_include_directories(streams PRIVATE
  ${ESMF_F90COMPILEPATHS}
  ${PIO_Fortran_INCLUDE_DIR}
  ${CMAKE_BINARY_DIR}/share
)

install(TARGETS streams ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
