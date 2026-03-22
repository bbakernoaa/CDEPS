# CMake generated Testfile for
# Source directory: /tide
# Build directory: /tide/build
#
# This file includes the relevant testing commands required for
# testing this directory and lists subdirectories to be tested as well.
add_test(tide_api_test "/tide/build/test_tide")
set_tests_properties(tide_api_test PROPERTIES  _BACKTRACE_TRIPLES "/tide/CMakeLists.txt;93;add_test;/tide/CMakeLists.txt;0;")
subdirs("_deps/yaml-cpp-build")
subdirs("share")
subdirs("streams")
subdirs("dshr")
