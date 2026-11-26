FROM althack/ros2:humble-gazebo

# if you have a nvidia card, use this instead to get HW acceleration:
# FROM althack/ros2:humble-cuda-gazebo

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        bluez \
        python3-vcstool \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

RUN usermod -a -G video,dialout,plugdev ros # for using dialout/ttys

# Set up auto-source of workspace for ros user
ARG WORKSPACE
RUN echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/ros/.bashrc
