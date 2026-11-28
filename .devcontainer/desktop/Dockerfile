# Desktop development and simulation: Humble desktop + Gazebo Fortress (ADR 0012).
# The base has no Gazebo. Fortress and everything the sim and perception need come from the
# ROS apt repo (packages.ros.org ships the Fortress libraries for jammy), the same source as
# on a native Humble install. No OSRF repo, no Gazebo Classic.
FROM althack/ros2:humble-desktop

# if you have a nvidia card, use this instead to get HW acceleration
# (and see the GPU notes in devcontainer.json):
# FROM althack/ros2:humble-cuda-desktop

# Simulation: Gazebo Fortress (`ign gazebo`, DART, ogre2 come in as hard dependencies of
# ros-humble-ros-gz), ros_gz bridge/image/sim and the ros2_control plugin.
# Perception and mapping (simulation milestone 2, pilsbot_vscode_ws#35): image transport,
# depth and stereo point clouds, rtabmap, the voxel layer for the costmaps.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        bluez \
        python3-vcstool \
        ros-humble-ros-gz \
        ros-humble-gz-ros2-control \
        ros-humble-compressed-image-transport \
        ros-humble-depth-image-proc \
        ros-humble-stereo-image-proc \
        ros-humble-rtabmap-ros \
        ros-humble-spatio-temporal-voxel-layer \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# video: /dev/dri/card*, dialout: ttys. The render node (/dev/dri/renderD*) belongs to the
# HOST's render group; its gid is added at run time, see devcontainer.json.
RUN usermod -a -G video,dialout,plugdev ros

# Set up auto-source of workspace for ros user
ARG WORKSPACE
RUN echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/ros/.bashrc
