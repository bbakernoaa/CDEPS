#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "cdeps_share" for configuration ""
set_property(TARGET cdeps_share APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(cdeps_share PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "Fortran"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libcdeps_share.a"
  )

list(APPEND _cmake_import_check_targets cdeps_share )
list(APPEND _cmake_import_check_files_for_cdeps_share "${_IMPORT_PREFIX}/lib/libcdeps_share.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
