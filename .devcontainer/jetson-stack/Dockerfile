# Nano stack container: everything except the camera, from Humble binaries.
# See docs/adr/0003-two-container-nano-runtime.md
# UNTESTED DRAFT: verify on the Nano (JetPack 4.6 host, arm64).
FROM ros:humble-ros-base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        bluez \
        git \
        sudo \
        python3-colcon-common-extensions \
        python3-vcstool \
        ros-humble-rmw-cyclonedds-cpp \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Must match the camera container (dustynv images default to CycloneDDS)
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Non-root user matching the host's first user
ARG USERNAME=ros
ARG USER_UID=1000
RUN groupadd -f i2c \
    && useradd -m -s /bin/bash -u ${USER_UID} ${USERNAME} \
    && usermod -a -G video,dialout,plugdev,i2c ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

ARG WORKSPACE
RUN echo "source /opt/ros/humble/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/${USERNAME}/.bashrc
