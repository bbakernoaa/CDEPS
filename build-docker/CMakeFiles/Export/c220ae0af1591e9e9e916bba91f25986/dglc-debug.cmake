#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "dglc" for configuration "DEBUG"
set_property(TARGET dglc APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(dglc PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "Fortran"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libdglc.a"
  )

list(APPEND _cmake_import_check_targets dglc )
list(APPEND _cmake_import_check_files_for_dglc "${_IMPORT_PREFIX}/lib/libdglc.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
