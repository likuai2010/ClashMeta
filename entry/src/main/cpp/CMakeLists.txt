# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(ClashForHarmonyOS)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

set(LIBS_DIR ${NATIVERENDER_ROOT_PATH}/)
#add_library(myapp SHARED IMPORTED)
#set_target_properties(myapp PROPERTIES IMPORTED_LOCATION ${LIBS_DIR}myapp.so)
include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)
#add_subdirectory(testC)
add_library(entry SHARED napi_init.cpp)

target_link_libraries(entry PUBLIC libace_napi.z.so )