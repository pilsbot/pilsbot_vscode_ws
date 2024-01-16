FROM pilsbot/foxy-jetson:dev

ENV AMENT_PREFIX_PATH=/opt/ros/foxy/install:/workspaces/addon_ws/install
ENV COLCON_PREFIX_PATH=/opt/ros/foxy/install:/workspaces/addon_ws/install
ENV LD_LIBRARY_PATH=/opt/ros/foxy/install/lib:/workspaces/addon_ws/install/lib
ENV PATH=/opt/ros/foxy/bin:$PATH
ENV PYTHONPATH=/opt/ros/foxy/lib/python3.6/site-packages:/workspaces/addon_ws/install/lib/python3.6/site-packages

ARG WORKSPACE

RUN mkdir -p /usr/src/jetson_multimedia_api
ADD jetson_multimedia_api /usr/src/jetson_multimedia_api

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

RUN sudo usermod -a -G video,i2c,dialout,plugdev,rdma ros

#[2024-01-16T21:38:00.248Z] W: GPG error: https://apt.kitware.com/ubuntu bionic InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 1A127079A92F09ED
#E: The repository 'https://apt.kitware.com/ubuntu bionic InRelease' is not signed.
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

RUN sudo apt update && sudo apt install --no-install-recommends -y \
    python3-serial \
    && rm -rf /var/lib/apt/lists/*

RUN sudo -H pip3 install transforms3d

RUN echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/ros/.bashrc
