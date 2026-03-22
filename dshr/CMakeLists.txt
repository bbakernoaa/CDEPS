set(SRCFILES dshr_dfield_mod.F90
              dshr_fldlist_mod.F90
              dshr_mod.F90)

add_library(dshr ${SRCFILES})

target_include_directories(dshr PRIVATE
  ${ESMF_F90COMPILEPATHS}
  ${PIO_Fortran_INCLUDE_DIR}
  ${CMAKE_BINARY_DIR}/share
)

install(TARGETS dshr ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
