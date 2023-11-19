#!/bin/bash
set -e

vcs import --recursive < src/ros2.repos src
sudo apt-get update
rosdep update --rosdistro=foxy
rosdep install --rosdistro=foxy --from-paths src --ignore-src -y
