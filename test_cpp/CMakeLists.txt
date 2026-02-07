cmake_minimum_required(VERSION 3.10)
project(RocksDBBackupTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

option(USE_NATIVE_ROCKSDB "Use natively-built RocksDB instead of Zig-built" OFF)

if(USE_NATIVE_ROCKSDB)
    # Using RocksDB built with MSVC
    message(STATUS "Using native MSVC-built RocksDB")
    
    if(NOT DEFINED ROCKSDB_BUILD_DIR)
        set(ROCKSDB_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build_rocksdb")
    endif()
    
    set(ROCKSDB_INCLUDE_DIR "$ENV{USERPROFILE}/AppData/Local/zig/p/N-V-__8AAEv0kgK0ypKHX8K7uy2ja2yMJb-o6B8pmW-B0ur5/include")
    set(ROCKSDB_LIB "${ROCKSDB_BUILD_DIR}/Release/rocksdb.lib")
    
    if(NOT EXISTS "${ROCKSDB_LIB}")
        message(FATAL_ERROR "RocksDB library not found at ${ROCKSDB_LIB}. Please run build_rocksdb_native.ps1 first.")
    endif()
else()
    # Using RocksDB built by Zig (will have ABI issues with MSVC)
    message(STATUS "Using Zig-built RocksDB (WARNING: may have ABI incompatibility)")
    
    set(ROCKSDB_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")
    set(ROCKSDB_INCLUDE_DIR "$ENV{USERPROFILE}/AppData/Local/zig/p/N-V-__8AAEv0kgK0ypKHX8K7uy2ja2yMJb-o6B8pmW-B0ur5/include")
    
    file(GLOB_RECURSE ROCKSDB_LIB_CANDIDATES "${ROCKSDB_ROOT}/.zig-cache/o/*/rocksdb.lib")
    if(ROCKSDB_LIB_CANDIDATES)
        list(GET ROCKSDB_LIB_CANDIDATES 0 ROCKSDB_LIB)
    else()
        set(ROCKSDB_LIB "${ROCKSDB_ROOT}/zig-out/lib/rocksdb.lib")
    endif()
    
    if(NOT EXISTS "${ROCKSDB_LIB}")
        message(FATAL_ERROR "Could not find rocksdb.lib. Please run 'zig build' first.")
    endif()
endif()

message(STATUS "RocksDB include: ${ROCKSDB_INCLUDE_DIR}")
message(STATUS "RocksDB library: ${ROCKSDB_LIB}")

include_directories(${ROCKSDB_INCLUDE_DIR})

# C API test (matches what Zig wrapper uses)
add_executable(test_c_api test_c_api.c)

target_link_libraries(test_c_api 
    ${ROCKSDB_LIB}
    rpcrt4  # UUID generation
    shlwapi # Path manipulation  
)

if(MSVC)
    set_property(TARGET test_c_api PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()
