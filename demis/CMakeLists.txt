project(demis Fortran)
set(SRCFILES  emis_comp_nuopc.F90)

foreach(FILE ${SRCFILES})
  if(EXISTS "${CASEROOT}/SourceMods/src.demis/${FILE}")
    list(REMOVE_ITEM SRCFILES ${FILE})
    list(APPEND SRCFILES "${CASEROOT}/SourceMods/src.demis/${FILE}")
    message("Using ${FILE} from ${CASEROOT}/SourceMods/src.demis")
  endif()
endforeach()

message("Demis srcfiles are ${SRCFILES}")

add_library(demis ${SRCFILES})

add_dependencies(demis dshr streams)
target_include_directories (demis PRIVATE ${ESMF_F90COMPILEPATHS})
target_include_directories (demis PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories (demis PRIVATE "${PIO_Fortran_INCLUDE_DIR}")
if(NOT DISABLE_FoX)
  target_include_directories (demis PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/../fox/include)
endif()

if(BLD_STANDALONE)
  # ESMX requires mod files
  foreach (SRC ${SRCFILES})
    string(REGEX REPLACE "[.]F90$" ".mod" MOD ${SRC})
    if (NOT DEFINED CIMEROOT AND MOD STREQUAL emis_comp_nuopc.mod)
      set(MOD cdeps_demis_comp.mod)
    endif()
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${MOD}" DESTINATION include)
  endforeach ()
endif()
