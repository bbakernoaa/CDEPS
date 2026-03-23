cmake_minimum_required(VERSION 3.10)
project(TIDE LANGUAGES CXX Fortran VERSION 0.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Options
option(WERROR "add the -Werror flag to compiler" OFF)

# Find Dependencies
find_package(ESMF REQUIRED)
find_package(MPI REQUIRED)
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
