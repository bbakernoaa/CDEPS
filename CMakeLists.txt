cmake_minimum_required(VERSION 3.10)
project(TIDE LANGUAGES CXX Fortran VERSION 0.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Options
option(WERROR "add the -Werror flag to compiler" OFF)

# Find Dependencies
if (DEFINED ENV{PIO_ROOT})
  message("PIO_ROOT is $ENV{PIO_ROOT}")
else()
  if (DEFINED PIO)
    set(PIO_PATH ${PIO})
  else()
    set(PIO_PATH $ENV{PIO})
  endif()
endif()

find_package(ESMF REQUIRED)
find_package(MPI REQUIRED)

# Use paths from ESMFMKFILE if available
if(EX_ESMF_FOUND)
  link_directories(${ESMF_F90ESMFLINKRPATHS})
endif()

# Hardcode PIO paths for JCSDA environment if find_package fails
set(PIO_C_LIBRARY "/opt/software/linux-ubuntu24.04-x86_64/gcc-13.3.0/parallelio-2.6.2-7b45pabda4ysavdoch6eielvyiwxramj/lib/libpioc.so")
set(PIO_C_INCLUDE_DIR "/opt/software/linux-ubuntu24.04-x86_64/gcc-13.3.0/parallelio-2.6.2-7b45pabda4ysavdoch6eielvyiwxramj/include")
set(PIO_Fortran_LIBRARY "/opt/software/linux-ubuntu24.04-x86_64/gcc-13.3.0/parallelio-2.6.2-7b45pabda4ysavdoch6eielvyiwxramj/lib/libpiof.so")
set(PIO_Fortran_INCLUDE_DIR "/opt/software/linux-ubuntu24.04-x86_64/gcc-13.3.0/parallelio-2.6.2-7b45pabda4ysavdoch6eielvyiwxramj/include")

find_package(PIO REQUIRED COMPONENTS C Fortran)

# yaml-cpp (Assuming it's available or can be fetched)
include(FetchContent)
FetchContent_Declare(
  yaml-cpp
  GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
  GIT_TAG yaml-cpp-0.7.0
)
FetchContent_MakeAvailable(yaml-cpp)

# TIDE Library
add_subdirectory(share)
add_subdirectory(streams)
add_subdirectory(dshr)

add_library(tide
  tide/src/tide_yaml_c.cpp
  tide/src/tide_yaml_mod.F90
  tide/src/tide_mod.F90
)

target_include_directories(tide PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tide/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/share>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/share>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/streams>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/streams>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/dshr>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/dshr>
)

target_include_directories(tide PRIVATE
  ${ESMF_F90COMPILEPATHS}
  ${PIO_Fortran_INCLUDE_DIR}
)

# Extract link directories from ESMF paths if they aren't already set
foreach(path ${ESMF_F90COMPILEPATHS})
  if(IS_DIRECTORY ${path}/../lib)
    link_directories(${path}/../lib)
  endif()
endforeach()
link_directories(/opt/views/view/lib)

target_link_libraries(tide PUBLIC
  cdeps_share
  streams
  dshr
  yaml-cpp
  ${ESMF_F90ESMFLINKLIBS}
  ${PIO_Fortran_LIBRARIES}
  ${MPI_Fortran_LIBRARIES}
  m
)

# Testing
enable_testing()
add_executable(test_tide tide/tests/test_tide.F90)
target_include_directories(test_tide PRIVATE
  ${ESMF_F90COMPILEPATHS}
)
target_link_libraries(test_tide PRIVATE tide
  ${ESMF_F90ESMFLINKLIBS}
  ${PIO_Fortran_LIBRARIES}
  ${MPI_Fortran_LIBRARIES}
  m
)
add_test(NAME tide_api_test COMMAND test_tide)

# Install rules
install(TARGETS tide cdeps_share streams dshr yaml-cpp EXPORT tide DESTINATION lib)
install(EXPORT tide DESTINATION lib/cmake)
