#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "FoX_wxml" for configuration "DEBUG"
set_property(TARGET FoX_wxml APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(FoX_wxml PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "Fortran"
  IMPORTED_LINK_INTERFACE_LIBRARIES_DEBUG "FoX_common;FoX_fsys"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libFoX_wxml.a"
  )

list(APPEND _cmake_import_check_targets FoX_wxml )
list(APPEND _cmake_import_check_files_for_FoX_wxml "${_IMPORT_PREFIX}/lib/libFoX_wxml.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
