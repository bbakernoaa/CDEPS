cmake_minimum_required(VERSION 3.10)
project(TIDE LANGUAGES CXX Fortran VERSION 0.1)

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
find_package(PIO REQUIRED COMPONENT C Fortran PATHS ${PIO_PATH})
find_package(MPI REQUIRED)

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
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/streams>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/dshr>
)

target_link_libraries(tide PUBLIC
  cdeps_share
  streams
  dshr
  yaml-cpp
  ESMF::ESMF
  PIO::piofortran
)

# Install rules
install(TARGETS tide EXPORT tide DESTINATION lib)
install(EXPORT tide DESTINATION lib/cmake)
