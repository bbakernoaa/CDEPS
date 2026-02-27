add_executable(test_dems_agg test_dems_agg.F90)
target_link_libraries(test_dems_agg dems streams dshr cdeps_share)
target_include_directories(test_dems_agg PRIVATE ${ESMF_F90COMPILEPATHS})
add_test(NAME dems_structural_test COMMAND test_dems_agg)
