#!/bin/bash
# Build the workspace. Extra arguments go to `colcon build`, e.g.
#   ./build.sh --packages-select pilsbot_driver
#   ./build.sh --parallel-workers 1      # on the 4 GB Nano
set -e

# Set the default build type
BUILD_TYPE=${BUILD_TYPE:-RelWithDebInfo}
colcon build \
        --merge-install \
        --symlink-install \
        "$@" \
        --cmake-args "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" "-DCMAKE_EXPORT_COMPILE_COMMANDS=On"
