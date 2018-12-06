cmake_minimum_required(VERSION 2.8.7)

project(GSLTests CXX)

# will make visual studio generated project group files
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

list(APPEND CATCH_CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external"
    "-DNO_SELFTEST=true"
)

if(GIT_FOUND)
    # add catch
    ExternalProject_Add(
        catch
        PREFIX ${CMAKE_BINARY_DIR}/catch
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG v2.0.1
        CMAKE_ARGS ${CATCH_CMAKE_ARGS}
        LOG_DOWNLOAD 1
        UPDATE_DISCONNECTED 1
    )
else()
    # assume catch is installed in a system directory
    add_custom_target(catch)
endif()

if (MSVC AND (GSL_CXX_STANDARD EQUAL 17))
    set(GSL_CPLUSPLUS_OPT -Zc:__cplusplus -permissive-)
endif()

# this interface adds compile options to how the tests are run
# please try to keep entries ordered =)
add_library(gsl_tests_config INTERFACE)
target_compile_options(gsl_tests_config INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:
        /EHsc
        /W4
        /WX
    >
    ${GSL_CPLUSPLUS_OPT}
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:
        -fno-strict-aliasing
        -Wall
        -Wcast-align
        -Wconversion
        -Wctor-dtor-privacy
        -Werror
        -Wextra
        -Wno-missing-braces
        -Wno-unknown-attributes
        -Wnon-virtual-dtor
        -Wold-style-cast
        -Woverloaded-virtual
        -Wpedantic
        -Wshadow
        -Wsign-conversion
    >
)

# for tests to find the catch header
target_include_directories(gsl_tests_config INTERFACE
    ${CMAKE_BINARY_DIR}/external/include
)

# set definitions for tests
target_compile_definitions(gsl_tests_config INTERFACE
    GSL_THROW_ON_CONTRACT_VIOLATION
)

# create the main executable for each test. this reduces the compile time
# of each test by pre-compiling catch.
add_library(test_catch STATIC test.cpp)
target_link_libraries(test_catch
    GSL
    gsl_tests_config
)
add_dependencies(test_catch catch)
set_property(TARGET test_catch PROPERTY FOLDER "GSL_tests")

function(add_gsl_test name)
    add_executable(${name} ${name}.cpp)
    target_link_libraries(${name}
        GSL
        test_catch
        gsl_tests_config
    )
    add_dependencies(${name} catch)
    add_test(
      ${name}
      ${name}
    )
    # group all tests under GSL_tests
    set_property(TARGET ${name} PROPERTY FOLDER "GSL_tests")
endfunction()

add_gsl_test(span_tests)

if(DEFINED ENV{APPVEYOR_JOB_NAME})
    message( STATUS "APPVEYOR_JOB_NAME : " $ENV{APPVEYOR_JOB_NAME} )
    set(ASM_LOCATION ${CMAKE_SOURCE_DIR}\\asm\\$ENV{APPVEYOR_JOB_NAME})
else()
    set(ASM_LOCATION ${CMAKE_SOURCE_DIR}\\asm\\${CMAKE_GENERATOR})
endif()

file(MAKE_DIRECTORY ${ASM_LOCATION})

add_custom_target(asm_tests)

function(add_gsl_asm_test name)
    add_library(${name}_asm ${name}.cpp)

    target_compile_options(${name}_asm PRIVATE
        $<$<CXX_COMPILER_ID:MSVC>:
            /FA
            /Fa${ASM_LOCATION}\\${name}_asm.asm
        >
        ${GSL_CPLUSPLUS_OPT}
        $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:
            -S
            -o ${ASM_LOCATION}\${name}.s
        >
    )

    target_link_libraries(${name}_asm
        GSL
        test_catch
        gsl_tests_config
    )
    add_dependencies(${name}_asm catch)
    add_dependencies(asm_tests ${name}_asm)
    # group all tests under GSL_tests
    set_property(TARGET ${name}_asm PROPERTY FOLDER "GSL_tests")
endfunction()

add_gsl_asm_test(no_exception_throw_tests)
add_gsl_asm_test(span_tests)