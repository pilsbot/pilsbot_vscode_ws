#!/bin/bash
# Build the workspace. Extra arguments go to `colcon build`, e.g.
#   ./build.sh --packages-select pilsbot_driver
#   MAKEFLAGS=-j1 ./build.sh --parallel-workers 1   # on the 4 GB Nano
# --parallel-workers limits the packages built at once; MAKEFLAGS=-j1 also limits the
# compiler jobs inside each package (colcon otherwise runs make -j<number of CPUs>).
#
# Do not pass --cmake-args: colcon keeps only the last --cmake-args, so it would drop
# this script's defaults (or the other way round). Put extra CMake arguments into
# PILSBOT_CMAKE_ARGS instead (split at spaces), e.g.
#   PILSBOT_CMAKE_ARGS="-DBUILD_TESTING=OFF" ./build.sh
set -e

# Set the default build type
BUILD_TYPE=${BUILD_TYPE:-RelWithDebInfo}
read -r -a extra_cmake_args <<< "${PILSBOT_CMAKE_ARGS:-}"
colcon build \
        --merge-install \
        --symlink-install \
        "$@" \
        --cmake-args "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" "-DCMAKE_EXPORT_COMPILE_COMMANDS=On" \
        "${extra_cmake_args[@]}"
