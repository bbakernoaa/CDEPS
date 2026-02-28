project(dems Fortran)
set(SRCFILES dems_comp.F90 dems_point_mapper.F90)

foreach(FILE ${SRCFILES})
  if(EXISTS "${CASEROOT}/SourceMods/src.dems/${FILE}")
    list(REMOVE_ITEM SRCFILES ${FILE})
    list(APPEND SRCFILES "${CASEROOT}/SourceMods/src.dems/${FILE}")
    message("Using ${FILE} from ${CASEROOT}/SourceMods/src.dems")
  endif()
endforeach()

message("DEMS srcfiles are ${SRCFILES}")

add_library(dems ${SRCFILES})

add_dependencies(dems dshr streams)
target_include_directories (dems PRIVATE ${ESMF_F90COMPILEPATHS})
target_include_directories (dems PRIVATE ${CMAKE_SOURCE_DIR})
target_include_directories (dems PRIVATE ${PIO_Fortran_INCLUDE_DIR})
if(NOT DISABLE_FoX)
  target_include_directories (dems PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/../fox/include)
endif()

if(BLD_STANDALONE)
  # ESMX requires mod files
  foreach (SRC ${SRCFILES})
    string(REGEX REPLACE "[.]F90$" ".mod" MOD ${SRC})
    if (NOT DEFINED CIMEROOT AND MOD STREQUAL dems_comp.mod)
      set(MOD cdeps_dems_comp.mod)
    endif()
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${MOD}" DESTINATION include)
  endforeach ()
endif()
