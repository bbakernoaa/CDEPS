set(SRCFILES  dshr_dfield_mod.F90
              dshr_fldlist_mod.F90
              dshr_mod.F90)

add_library(dshr ${SRCFILES})
target_compile_options(dshr PRIVATE -Wno-line-truncation)

target_include_directories(dshr PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

target_include_directories(dshr PRIVATE
  ${ESMF_F90COMPILEPATHS}
  ${PIO_Fortran_INCLUDE_DIR}
  ${CMAKE_BINARY_DIR}/share
  ${CMAKE_BINARY_DIR}/streams
)

add_dependencies(dshr cdeps_share streams)

install(TARGETS dshr ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
