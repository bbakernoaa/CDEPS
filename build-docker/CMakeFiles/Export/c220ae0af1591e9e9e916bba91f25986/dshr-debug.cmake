#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "dshr" for configuration "DEBUG"
set_property(TARGET dshr APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(dshr PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "Fortran"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libdshr.a"
  )

list(APPEND _cmake_import_check_targets dshr )
list(APPEND _cmake_import_check_files_for_dshr "${_IMPORT_PREFIX}/lib/libdshr.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
