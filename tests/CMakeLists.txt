add_executable(test_tide test_tide.F90)

target_link_libraries(test_tide streams cdeps_share)

add_test(NAME test_tide COMMAND test_tide)