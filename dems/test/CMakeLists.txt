add_executable(test_point_mapper test_point_mapper.F90)
target_link_libraries(test_point_mapper dems dshr streams ${ESMF_F90LINKLIBS})
target_include_directories(test_point_mapper PRIVATE ${CMAKE_SOURCE_DIR})
add_test(NAME test_point_mapper COMMAND test_point_mapper)
