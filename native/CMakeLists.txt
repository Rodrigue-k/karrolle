cmake_minimum_required(VERSION 3.10)

project(karrolle_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

add_library(karrolle_engine SHARED
    src/engine.cpp
)

set_target_properties(karrolle_engine PROPERTIES
    PUBLIC_HEADER include/engine.h
)

if(WIN32)
    target_compile_definitions(karrolle_engine PRIVATE KARROLLE_EXPORT)
endif()
