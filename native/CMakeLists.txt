cmake_minimum_required(VERSION 3.10)
project(karrolle_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
set(SOURCES
    src/engine.cpp
    src/core/scene.cpp
    third_party/zip/zip.c
    third_party/tinyxml2/tinyxml2.cpp
)

# Header files for IDE support
set(HEADERS
    include/engine.h
    src/core/scene.hpp
    src/core/object.hpp
    src/core/font.hpp
    src/core/utils.hpp
    src/objects/rect_object.hpp
    src/objects/text_object.hpp
    src/objects/image_object.hpp
    third_party/zip/zip.h
    third_party/zip/miniz.h
    third_party/tinyxml2/tinyxml2.h
)

add_library(karrolle_engine SHARED ${SOURCES} ${HEADERS})

# Set the output name to 'engine' so Dart can load 'engine.dll'
set_target_properties(karrolle_engine PROPERTIES OUTPUT_NAME "engine")

target_include_directories(karrolle_engine PRIVATE 
    include
    src
    deps
    third_party/zip
    third_party/tinyxml2
)

# Compile flags
if(MSVC)
    target_compile_options(karrolle_engine PRIVATE /W4 /WX-)
    target_compile_definitions(karrolle_engine PRIVATE KARROLLE_EXPORT _CRT_SECURE_NO_WARNINGS)
else()
    target_compile_options(karrolle_engine PRIVATE -Wall -Wextra)
endif()

# Set output directory to match Flutter's expectations
set_target_properties(karrolle_engine PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
