# Nano camera container: owns the OAK and Jetson hardware decoding (GStreamer nvjpegdec / nvv4l2decoder).
# See docs/adr/0003-two-container-nano-runtime.md and docs/adr/0004-own-oak-driver-with-hardware-decoding.md
# UNTESTED DRAFT: verify on the Nano. ROS here is built from source (Ubuntu 18.04, gcc-8, Python 3.6);
# `apt install ros-humble-*` does not work.
FROM dustynv/ros:humble-ros-base-l4t-r32.7.1

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        libusb-1.0-0-dev \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# The NVIDIA GStreamer elements (nvv4l2decoder, nvjpegdec, nvvidconv) come from the host via
# --runtime=nvidia (verified on the robot's Foxy container). jetson_multimedia_api is not needed.
# TODO(camera-container): build luxonis/depthai-core from source (see src/jetson-camera.repos)
# with CC=gcc-8 CXX=g++-8 before building depthai-ros.

ENV CC=gcc-8 CXX=g++-8
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

ARG WORKSPACE
RUN echo "source /opt/ros/humble/install/setup.bash" >> /root/.bashrc \
    && echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /root/.bashrc
