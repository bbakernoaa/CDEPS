#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "dice" for configuration "DEBUG"
set_property(TARGET dice APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(dice PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "Fortran"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libdice.a"
  )

list(APPEND _cmake_import_check_targets dice )
list(APPEND _cmake_import_check_files_for_dice "${_IMPORT_PREFIX}/lib/libdice.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
