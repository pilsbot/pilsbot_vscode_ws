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

# Non-root user matching the host's first user. Create it before any extra group, so that
# its own group gets gid USER_UID as on the host.
# Device groups (input for the gamepad, i2c for the port expander) differ between image and
# host. The gids that count are the host's: pass them at run time with --group-add, see README.
ARG USERNAME=ros
ARG USER_UID=1000
RUN useradd -m -s /bin/bash -u ${USER_UID} ${USERNAME} \
    && groupadd -r -f i2c \
    && groupadd -r -f input \
    && usermod -a -G video,dialout,plugdev,i2c,input ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

ARG WORKSPACE
RUN echo "source /opt/ros/humble/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/${USERNAME}/.bashrc
