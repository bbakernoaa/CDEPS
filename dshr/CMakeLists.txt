set(SRCFILES dshr_dfield_mod.F90
              dshr_fldlist_mod.F90
              dshr_mod.F90)

add_library(dshr ${SRCFILES})
target_compile_options(dshr PRIVATE -Wno-line-truncation)

target_include_directories(dshr PRIVATE
  ${ESMF_F90COMPILEPATHS}
  ${PIO_Fortran_INCLUDE_DIR}
  $<TARGET_PROPERTY:cdeps_share,INTERFACE_INCLUDE_DIRECTORIES>
  $<TARGET_PROPERTY:streams,INTERFACE_INCLUDE_DIRECTORIES>
)

install(TARGETS dshr ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
