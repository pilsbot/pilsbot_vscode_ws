#FROM althack/ros2:foxy-gazebo

# if you have a nvidia card, add instead type
FROM althack/ros2:foxy-gazebo-nvidia
# to get HW acceleration

# ** [Optional] Uncomment this section to install additional packages. **
#
ENV DEBIAN_FRONTEND=noninteractive
 RUN apt-get update \
    && apt-get -y install --no-install-recommends bluez \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
 ENV DEBIAN_FRONTEND=dialog

RUN pip3 install transforms3d # seems to be missing from nmea_navsat_driver dependencies?
RUN usermod -a -G video,dialout,plugdev ros # for using dialout/ttys

# Set up auto-source of workspace for ros user
ARG WORKSPACE
RUN echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/ros/.bashrc
