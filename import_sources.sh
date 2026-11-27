#!/bin/bash
# Import sources and install their dependencies.
#
# Keep this name; never put a script called setup.sh in the workspace root.
# /opt/ros/<distro>/setup.bash is ament's prefix-level script: it sources
# "$(dirname "${BASH_SOURCE[0]}")/setup.sh". In zsh BASH_SOURCE is empty, so
# that resolves to ./setup.sh in the current directory and would run it
# (pilsbot/pilsbot_vscode_ws#30).
#
# Usage: ./import_sources.sh [--no-deps] [REPOS_FILE...]
#   Default repos files: src/ros2.repos src/desktop.repos
#   Nano stack container:  ./import_sources.sh src/ros2.repos
#   Nano camera container: ./import_sources.sh src/jetson-camera.repos
set -e

INSTALL_DEPS=1
REPOS_FILES=()
for arg in "$@"; do
    case "$arg" in
        --no-deps) INSTALL_DEPS=0 ;;
        *) REPOS_FILES+=("$arg") ;;
    esac
done
if [ ${#REPOS_FILES[@]} -eq 0 ]; then
    REPOS_FILES=(src/ros2.repos src/desktop.repos)
fi

for repos in "${REPOS_FILES[@]}"; do
    echo "Importing $repos"
    vcs import --recursive --skip-existing src < "$repos"
done

if [ "$INSTALL_DEPS" -eq 1 ]; then
    : "${ROS_DISTRO:?ROS_DISTRO is not set; source /opt/ros/<distro>/setup.bash first}"
    sudo apt-get update
    rosdep update --rosdistro="$ROS_DISTRO"
    rosdep install --rosdistro="$ROS_DISTRO" --from-paths src --ignore-src -y
fi
