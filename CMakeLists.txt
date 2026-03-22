cmake_minimum_required(VERSION 3.10)

project(TIDE LANGUAGES Fortran VERSION 0.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
enable_language(Fortran)

if (TARGET esmf)
  message("Target esmf is already found. Skip find_package ...")
else()
  find_package(ESMF REQUIRED)
endif()

if (DEFINED ENV{PIO_ROOT})
  message("PIO_ROOT is $ENV{PIO_ROOT}")
else()
  if (DEFINED PIO)
    set(PIO_PATH ${PIO})
  else()
    set(PIO_PATH $ENV{PIO})
  endif()
  find_package(PIO REQUIRED COMPONENT C Fortran PATH ${PIO_PATH})
endif()

if (NOT DEFINED MPILIB OR NOT ${MPILIB} STREQUAL "mpi-serial")
  find_package(MPI REQUIRED)
endif()

add_subdirectory(share)
list(APPEND EXTRA_LIBS cdeps_share)

if("${COMPILER}" STREQUAL "nag")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -D__NAG__")
endif()

add_subdirectory(streams)

foreach(DEPS streams cdeps_share)
  install(TARGETS ${DEPS}
          EXPORT  ${DEPS}
          ARCHIVE DESTINATION lib
          LIBRARY DESTINATION lib
          COMPONENT Library)
  install(EXPORT      ${DEPS}
          DESTINATION lib/cmake)
endforeach(DEPS)
