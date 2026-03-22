# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/app/build/share/genf90/src/genf90"
  "/app/build/share/genf90/src/genf90-build"
  "/app/build/share/genf90"
  "/app/build/share/genf90/tmp"
  "/app/build/share/genf90/src/genf90-stamp"
  "/app/build/share/genf90/src"
  "/app/build/share/genf90/src/genf90-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/app/build/share/genf90/src/genf90-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/app/build/share/genf90/src/genf90-stamp${cfgdir}") # cfgdir has leading slash
endif()
