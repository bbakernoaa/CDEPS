#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "FoX_common" for configuration "DEBUG"
set_property(TARGET FoX_common APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(FoX_common PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "Fortran"
  IMPORTED_LINK_INTERFACE_LIBRARIES_DEBUG "FoX_utils;FoX_fsys"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libFoX_common.a"
  )

list(APPEND _cmake_import_check_targets FoX_common )
list(APPEND _cmake_import_check_files_for_FoX_common "${_IMPORT_PREFIX}/lib/libFoX_common.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
