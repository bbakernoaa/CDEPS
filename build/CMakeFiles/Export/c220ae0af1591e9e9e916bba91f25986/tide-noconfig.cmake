#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "tide" for configuration ""
set_property(TARGET tide APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(tide PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX;Fortran"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libtide.a"
  )

list(APPEND _cmake_import_check_targets tide )
list(APPEND _cmake_import_check_files_for_tide "${_IMPORT_PREFIX}/lib/libtide.a" )

# Import target "cdeps_share" for configuration ""
set_property(TARGET cdeps_share APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(cdeps_share PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "Fortran"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libcdeps_share.a"
  )

list(APPEND _cmake_import_check_targets cdeps_share )
list(APPEND _cmake_import_check_files_for_cdeps_share "${_IMPORT_PREFIX}/lib/libcdeps_share.a" )

# Import target "streams" for configuration ""
set_property(TARGET streams APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(streams PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "Fortran"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libstreams.a"
  )

list(APPEND _cmake_import_check_targets streams )
list(APPEND _cmake_import_check_files_for_streams "${_IMPORT_PREFIX}/lib/libstreams.a" )

# Import target "dshr" for configuration ""
set_property(TARGET dshr APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(dshr PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "Fortran"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libdshr.a"
  )

list(APPEND _cmake_import_check_targets dshr )
list(APPEND _cmake_import_check_files_for_dshr "${_IMPORT_PREFIX}/lib/libdshr.a" )

# Import target "yaml-cpp" for configuration ""
set_property(TARGET yaml-cpp APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(yaml-cpp PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libyaml-cpp.a"
  )

list(APPEND _cmake_import_check_targets yaml-cpp )
list(APPEND _cmake_import_check_files_for_yaml-cpp "${_IMPORT_PREFIX}/lib/libyaml-cpp.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
