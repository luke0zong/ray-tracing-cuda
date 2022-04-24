cmake_minimum_required ( VERSION 3.11 )
project(cuda_ray_tracing)
set ( CMAKE_CXX_STANDARD 14 )

include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
  enable_language(CUDA)
  if(NOT DEFINED CMAKE_CUDA_STANDARD)
    set(CMAKE_CUDA_STANDARD 11)
    set(CMAKE_CUDA_STANDARD_REQUIRED ON)
  endif()
  set(CMAKE_CUDA_SEPARABLE_COMPILATION ON)
else()
  message(STATUS "No CUDA support")
endif()

# Suppress warnings about stack size
set( CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xnvlink --suppress-stack-size-warning" CACHE STRING "" FORCE)

set ( SOURCE_CUDA
  src/camera.cuh
  src/ray.cuh
  src/vec3.cuh
  src/aabb.cuh
  src/texture.cuh
  src/bvh.cuh
  src/moving_sphere.cuh
  src/hittable.cuh
  src/hittable_list.cuh
  src/material.cuh
  src/sphere.cuh
  src/main.cu
  )

add_executable(${PROJECT_NAME} ${SOURCE_CUDA})

# Include Eigen for linear algebra, stb to export images.
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/external/eigen" "${CMAKE_CURRENT_SOURCE_DIR}/external/stb")

# set cuda standard to 14
set_property(TARGET ${PROJECT_NAME} PROPERTY CUDA_STANDARD 14)