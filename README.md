# Pilsbot ROS2 Workspace

This repository contains a preconfigured workspace for development of the Pilsbot platform. The branch `humble` is the primary development line. The branch `foxy` is the maintained legacy line, which receives backports of substantial improvements (see [docs/adr](docs/adr)).

One branch serves every target. The targets differ only in which repos files they import and which devcontainer they use:

| Target | Devcontainer | Repos files |
|---|---|---|
| Desktop development and simulation | `.devcontainer/desktop` | `src/ros2.repos`, `src/desktop.repos` (default) |
| Jetson Nano, everything except the camera | `.devcontainer/jetson-stack` | `src/ros2.repos` |
| Jetson Nano, OAK camera with hardware decoding | `.devcontainer/jetson-camera` | `src/jetson-camera.repos` |

The Nano runs two containers side by side; see [ADR 0003](docs/adr/0003-two-container-nano-runtime.md). Project vocabulary lives in [GLOSSARY.md](GLOSSARY.md).

## Deliberate differences from the Foxy line

The Humble line is not a plain port. On the robot it behaves differently from Foxy in these ways, all on purpose:

- **Startup:** the hardware and the controllers come up inactive and are activated by the hardware activator, at least 5 s after the launch ([ADR 0007](docs/adr/0007-inactive-hardware-and-activator.md)).
- **Hoverboard power:** the power toggle runs in the Head MCU thread instead of sleeping about 1 s in the control loop. It is never pressed after an error, only on 1 s of silence and on clean shutdown ([ADR 0008](docs/adr/0008-hoverboard-power-blind-toggle.md)). The driver measures its timeouts on the steady clock, not the system clock.
- **Lost Head MCU:** the steering angle and endstops become NaN at once, and the driver reconnects once a second until the Head MCU is back. Before, the angle froze at its last value and the controller kept steering on it.
- **Controller stops:**
  - NaN steering or wheel positions halt the wheels, and the speed ramps up from standstill afterwards.
  - A `cmd_vel` timeout (0.5 s) stops the wheels in the same cycle. Foxy ramped down at the acceleration limit, which took up to about 5 s from full speed.
  - The steering-error stop can now fire: linear speed goes to 0 while the steering angle is more than `angle.z.max_angle_setpoint_diff` (0.85 rad) from its setpoint and the steering loop has authority. On Foxy it compared the PID output and never fired.
- **Odometry:** `/odom` and its TF are stamped with ROS time (Foxy: the steady clock), and they track `base_footprint` at the rear axle centre in `odom` ([ADR 0002](docs/adr/0002-rear-axle-centre-reference-point.md)).
- **Sensor topics:** `/dynamic_joint_states` replaces `/hoverboard_api` and `/head_mcu` ([ADR 0006](docs/adr/0006-prefer-lasting-ros2-standards.md)).
- **Supervision:** if `ros2_control_node` exits, the whole launch ends and systemd restarts the stack with the motors switched off in between. The lighting bridge and the GNSS driver respawn every 5 s while their port is missing ([ADR 0011](docs/adr/0011-nano-start-path-and-supervision.md)).
- **Recording and Foxglove:** Kohlfahrt logs are MCAP split every 300 s, nothing is recorded without the SSD, and Foxglove is read-only ([ADR 0010](docs/adr/0010-recording-and-foxglove-on-the-robot.md)).
- **Gamepad:** Humble's SDL `joy_node` selects the gamepad by index or name from the robot profile ([ADR 0009](docs/adr/0009-robot-profile-single-source.md)) and reads `/dev/input/event*`. The button and axis mapping is not yet checked against SDL.
- **Cameras:** the stack starts no camera; the camera container does ([ADR 0003](docs/adr/0003-two-container-nano-runtime.md)). During the transition it runs the Foxy camera nodes unchanged (OAK `rgb_stereo_node` at 480p and 10 fps). After the move to Humble the OAK runs `mjpeg_node` (colour 1280×720 at 30 fps, [ADR 0004](docs/adr/0004-own-oak-driver-with-hardware-decoding.md)), and the OAK's `camera_info` is not recorded.

## How to use this workspace

### Prerequisites

You should already have Docker and VSCode with the remote containers plugin installed on your system.

* [docker](https://docs.docker.com/engine/install/)
* [vscode](https://code.visualstudio.com/)
* [vscode dev containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Open it in vscode

Clone the repository to a folder of your choice with

```
git clone https://github.com/pilsbot/pilsbot_vscode_ws.git
```

or via ssh

```
git clone git@github.com:pilsbot/pilsbot_vscode_ws.git
```

Now that you've cloned your repo onto your computer, you can open it in VSCode (File->Open Folder). 

When you open it for the first time, you should see a little popup that asks you if you would like to open it in a container.  Say yes!

![template_vscode](https://user-images.githubusercontent.com/6098197/91332551-36898100-e781-11ea-9080-729964373719.png)

If you don't see the pop-up, click on the little green square in the bottom left corner, which should bring up the container dialog

![template_vscode_bottom](https://user-images.githubusercontent.com/6098197/91332638-5d47b780-e781-11ea-9fb6-4d134dbfc464.png)

In the dialog, select "Dev Containers: Reopen in Container" and pick the configuration for your target

VSCode will build the dockerfile inside of `.devcontainer` for you.  If you open a terminal inside VSCode (Terminal->New Terminal), you should see that your username has been changed to `ros`, and the bottom left green corner should say "Dev Container"

![template_container](https://user-images.githubusercontent.com/6098197/91332895-adbf1500-e781-11ea-8afc-7a22a5340d4a.png)


### Setup the workspace

1. Import the sources and install their dependencies with `./import_sources.sh` (desktop default), or pass the repos files for your target, e.g. `./import_sources.sh src/ros2.repos`. The tasks `Terminal->Run Task..->setup` and `import from workspace file` do the same and ask for the target.
2. Run the build task with `Ctrl+Shift+B`, or `./build.sh`. Set `BUILD_TYPE` to override the default `RelWithDebInfo`.

### Check the build

```
source install/setup.bash
ros2 pkg executables pilsbot_driver   # lists hardware_activator
xacro $(ros2 pkg prefix pilsbot_description)/share/pilsbot_description/urdf/pilsbot.urdf.xacro hardware:=real > /dev/null
```

The URDF has no default hardware mode: without `hardware:=real` or `hardware:=gazebo`, xacro stops with a message that names the argument.

`./build.sh` passes extra arguments to `colcon build`, e.g. `./build.sh --packages-select pilsbot_driver` or `./build.sh --packages-skip <name>`.

### Simulation

On the desktop, `pilsbot_simulation` runs the robot in Gazebo Fortress through the robot's own launch files and controller config, with `hardware:=gazebo` ([ADR 0012](docs/adr/0012-simulation-on-gazebo-fortress.md)). It needs `ros-humble-ros-gz` and `ros-humble-gz-ros2-control`; Gazebo Classic is not supported. The desktop devcontainer ships both, from the ROS apt repo, together with the perception and mapping packages (`depth_image_proc`, `stereo_image_proc`, `rtabmap_ros`, the spatio-temporal voxel layer, compressed image transport).

The devcontainer renders OpenGL in software by default, which runs the Gazebo GUI everywhere but slowly. To render on the GPU (Intel or AMD), export these on the host before opening the container, then start VS Code from that shell (close other VS Code windows first, or the running instance keeps its old environment):

```
export LIBGL_ALWAYS_SOFTWARE=0
export PILSBOT_RENDER_GID=$(getent group render | cut -d: -f3)   # access to /dev/dri/renderD*
```

If they do not reach the container, Gazebo silently stays on software rendering. Check inside the container: `echo $LIBGL_ALWAYS_SOFTWARE` must print `0`, and `id` must list the host's render gid.

With an nvidia card, use the `humble-cuda-desktop` base named in `.devcontainer/desktop/Dockerfile` and add `--gpus=all` to the run arguments.

```
ros2 launch pilsbot_simulation sim.launch.py              # with the Gazebo GUI
ros2 launch pilsbot_simulation sim.launch.py gui:=false   # headless
ros2 launch pilsbot_simulation sim.launch.py world:=citysim_block   # city block (world:=citysim: the full city, which does not drive on the desktop yet, ADR 0013)
ros2 launch pilsbot_simulation sim.launch.py cameras:=false         # no camera sensors, faster
```

The city worlds come from `citysim` (`src/desktop.repos`) and download about 110 MB of Fuel models to `~/.ignition/fuel` on the first launch. Point clouds and the local costmap come from `pilsbot_navigation`, started next to the sim with `use_sim_time:=true`: `perception.launch.py cloud:=depth|stereo` publishes `/camera/points`, and `local_costmap.launch.py` reads it ([ADR 0013](docs/adr/0013-camera-and-point-cloud-pipeline.md)). On a desktop with CMake 4, citysim's plugins build only with `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`.

Drive with the gamepad as on the robot, or see the [pilsbot_simulation README](https://github.com/pilsbot/pilsbot_simulation/tree/humble) for commands without one, Foxglove, the bridged topics and the headless drive test. The controllers become active one hardware activator period (5 s) of sim time after the launch; the sim runs below real time with the cameras on, so on the wall clock this takes longer. Odometry, frames and topics are the robot's; the remaining differences are listed in ADR 0012 and ADR 0013.

If any issues occur during the setup process, do not hesitate to open an issue, so we can
fix the problem as soon as possible.

## On the Jetson Nano

The Humble stack container lives next to the Foxy stack, which stays as it is: Foxy in `~/pilsbot_vscode_ws` (container `pilsbot_stack`, started by `pilsbot_stack.service` from [useful-scripts](https://github.com/pilsbot/useful-scripts)), Humble in a second workspace `~/pilsbot_humble_ws` with the image `pilsbot/humble-stack` and the container `pilsbot-humble`. Never run both stacks at the same time: both drive the same serial ports, I2C port expander and gamepad.

### Build the image

JetPack 4.6 ships an old Docker whose seccomp profile does not know `clone3`, which Ubuntu 22.04 uses. `docker run` works around it with `--security-opt seccomp=unconfined`, but `docker build` cannot, so `RUN apt-get update` may fail while building. Check the Docker version on the Nano first:

```
docker version --format '{{.Server.Version}}'
```

- 20.10.10 or newer: build on the Nano.

  ```
  git clone -b humble https://github.com/pilsbot/pilsbot_vscode_ws.git ~/pilsbot_humble_ws
  cd ~/pilsbot_humble_ws
  docker build -t pilsbot/humble-stack \
    --build-arg WORKSPACE=/workspaces/pilsbot_humble_ws .devcontainer/jetson-stack
  ```

  Add `--build-arg USER_UID=$(id -u)` if `id -u` is not 1000.
- Older, or the build fails with `clone3`, `Operation not permitted` or `pthread_create` errors: build for arm64 on a desktop (about 4 minutes under qemu) and copy the image over.

  ```
  docker run --privileged --rm tonistiigi/binfmt --install arm64   # once, enables qemu
  docker buildx build --platform linux/arm64 --load -t pilsbot/humble-stack \
    --build-arg WORKSPACE=/workspaces/pilsbot_humble_ws .devcontainer/jetson-stack
  docker save pilsbot/humble-stack | ssh pilsbot@<nano> docker load
  ```

### Start the container

The Foxy service also prepares the hardware: its `startall.bash` runs `enable_motors.bash` (switches the motor power on through the MCP23017 port expander at I2C 0x20), `setup_serials.bash` (stops `serial-getty` and creates `/dev/ttyHoverboard`, `/dev/ttyHeadMCU` and `/dev/ttyGPS`), the Foxy container, and `disable_motors.bash` when the container exits. The Humble container does none of this, so on the Nano run, in this order:

```
# 1. Stop Foxy. `stop` lasts until the next reboot only: the service is enabled and
#    starts Foxy again at boot. After a reboot, stop it again before starting Humble.
sudo systemctl stop pilsbot_stack
docker ps                                   # must not list pilsbot_stack

# 2. Prepare the hardware like the service does (the symlinks in /dev do not survive a reboot)
bash ~/useful-scripts/setup_serials.bash    # calls sudo itself; at the end, ttyHeadMCU and ttyGPS must point to devices
sudo ~/useful-scripts/enable_motors.bash

# 3. Start the Humble container (first time; later `docker start pilsbot-humble`)
docker run -d --name pilsbot-humble --network=host --ipc=host --privileged \
  --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
  --group-add "$(getent group input | cut -d: -f3)" \
  --group-add "$(getent group i2c | cut -d: -f3)" \
  -v /dev:/dev -v /run/udev:/run/udev:ro \
  -v ~/pilsbot_humble_ws:/workspaces/pilsbot_humble_ws \
  --mount type=bind,source=/media/externSSD/bags,target=/workspaces/bags \
  -e ROS_LOG_DIR=/workspaces/pilsbot_humble_ws/log/ros \
  -u ros -w /workspaces/pilsbot_humble_ws pilsbot/humble-stack sleep infinity
docker exec -it pilsbot-humble bash
./import_sources.sh src/ros2.repos
MAKEFLAGS=-j1 ./build.sh --parallel-workers 1   # the 4 GB Nano runs out of memory otherwise

# 4. When done testing: stop the container, then switch the motors off
docker stop pilsbot-humble
sudo ~/useful-scripts/disable_motors.bash
```

`~/useful-scripts` is `/home/pilsbot/useful-scripts`, where `pilsbot_stack.service` expects it. To return to Foxy without a reboot: `sudo systemctl start pilsbot_stack`. Do not `systemctl disable` the service for a test; a reboot is the way back to the normal Foxy robot. The Humble container has no `--restart` policy, so after a reboot only Foxy runs.

Why the flags:

- `--group-add`: `--privileged` lets the container open devices, but the user `ros` still needs file permissions. Humble's `joy_node` (SDL) reads the gamepad from `/dev/input/event*` (`root:input`, mode 0660), Foxy read the world-readable `/dev/input/js0`. The port expander uses `/dev/i2c-*` (group `i2c`). The gids must be the host's, which differ from the image's, so they are looked up on the host. Check that both `getent` calls print a line; `ls -ln /dev/input/event* /dev/i2c-*` shows the gids the devices really use.
- `-v /run/udev:/run/udev:ro`: SDL learns about gamepads that connect later through udev.
- `--mount` instead of `-v` for the bags: it fails if `/media/externSSD/bags` does not exist, where `-v` would create it. That does not prove the SSD is mounted: the Foxy service binds the same path with `--volume`, so if Foxy ever started without the SSD, the directory exists on the root file system and `--mount` binds it. The real guard is in the recording launch (`log_kohl.launch.py`, pilsbot_bringup): it records only if `<output_dir>/.pilsbot_bags` exists. Create that marker once, with the SSD mounted:

  ```
  mountpoint /media/externSSD && sudo touch /media/externSSD/bags/.pilsbot_bags
  ```

  Without the SSD, the recording launch prints a `NOT RECORDING` banner and the rest of the stack runs. To record elsewhere, create the marker in that directory and bind it instead.

The VS Code devcontainer `.devcontainer/jetson-stack` uses the same flags, and needs the same steps 1, 2 and 4 on the host. For `--group-add` it reads `PILSBOT_INPUT_GID` and `PILSBOT_I2C_GID` from the environment of the VS Code process that opens the container. Export them, then start VS Code from that shell (close other VS Code windows first, or the running instance keeps its old environment):

```
export PILSBOT_INPUT_GID=$(getent group input | cut -d: -f3)
export PILSBOT_I2C_GID=$(getent group i2c | cut -d: -f3)
code ~/pilsbot_humble_ws
```

If they are unset, the devcontainer falls back to the group names `input` and `i2c`, which resolve to the image's own groups. `ros` is already in those, so nothing is granted and the gamepad and I2C fail with "Permission denied". Check inside the container: `id` must list the two host gids.

The camera container (`.devcontainer/jetson-camera`) runs as `root`, not `ros`, so it needs no group settings. It records nothing and does not mount the bags.

### DDS

Both containers use CycloneDDS (`RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`) on the host network, and must use the same `ROS_DOMAIN_ID` (default 0; set it with `-e ROS_DOMAIN_ID=<n>` in both, and on a laptop that runs `ros2` commands against the robot). Foxglove connects over its WebSocket (port 8765) and does not depend on DDS.

The Nano has several network interfaces (`docker0`, `l4tbr0`, `wlan0`, ...), and CycloneDDS may pick one the laptop cannot reach. If `ros2 topic list` on the laptop sees nothing from the robot, pin the interface with the shipped config by adding to `docker run`:

```
-e CYCLONEDDS_URI=file:///workspaces/pilsbot_humble_ws/.devcontainer/jetson-stack/cyclonedds.xml \
-e PILSBOT_DDS_INTERFACE=wlan0
```

Take the interface name from `ip -br addr` on the Nano. Before using it, know what it costs:

- CycloneDDS refuses to start a node when the named interface does not exist, and probably also when it has no IP address (wifi not connected, no access point on an outing). Then no node starts, the driver included, so the robot does not drive.
- The camera container must use the same setting (the same two variables, with the path to `cyclonedds.xml` in its workspace). If one container is pinned and the other is not, they may pick different interfaces and not see each other's topics.

So leave it off for outings, and use it only when the laptop really cannot see the robot.

## Good to know

- all packages added to the workspace should use `https`. If you have a Github account logged in your VSCode installation, you can easily push without the need for password authentication. You will be asked to acknowledge your login once via your browser and you're good to go.

## Cameras on the Nano during the transition

On Humble, the stack container starts no camera (`kohlfahrt_teleop_and_log` neither): the cameras belong to the camera container ([ADR 0003](docs/adr/0003-two-container-nano-runtime.md)). Until that container moves to the dustynv Humble image (`.devcontainer/jetson-camera`, `src/jetson-camera.repos`), it runs on Foxy:

- **Workspace:** the Foxy workspace `~/pilsbot_vscode_ws` as the Foxy stack built it (`pilsbot_depthai` on `foxy-devel`, `jetson_camera` on `master`). Nothing is checked out or rebuilt, so the Foxy stack stays as it is.
- **Image:** the one `pilsbot_stack.service` uses, named in `container=` in `~/useful-scripts/start_latest_pilsbot_stack.sh`.
- **Launch:** the Foxy `pilsbot_bringup` has no `camera.launch.py`, so the container starts the two camera launches directly, with the settings of the Foxy Kohl mode (OAK-D Lite, 480p at 10 fps). `publish_urdf:=false`, because the Humble stack already publishes the OAK's frames from `pilsbot_description`.

Run it next to the Humble stack container `pilsbot-humble`, never next to the Foxy stack, which starts the same cameras itself (`sudo systemctl stop pilsbot_stack` first):

```
FOXY_IMAGE=$(sed -n 's/^container=//p' ~/useful-scripts/start_latest_pilsbot_stack.sh)
docker run -d --name pilsbot-camera --privileged --user ros --gpus=all \
  --network=host --cap-add=SYS_PTRACE \
  --security-opt=seccomp:unconfined --security-opt=apparmor:unconfined \
  -v /tmp/argus_socket:/tmp/argus_socket -v /dev:/dev \
  -v /home/pilsbot/pilsbot_vscode_ws:/workspaces/pilsbot_vscode_ws \
  "$FOXY_IMAGE" bash -c '
    trap "kill -INT \$(jobs -p)" INT TERM   # docker stop: shut both launches down cleanly
    . /workspaces/pilsbot_vscode_ws/install/local_setup.bash
    ros2 launch pilsbot_depthai rgb_stereo_node.launch.py camera_model:=OAK-D-LITE \
      colorResolution:=480p colorFramerate:=10 monoResolution:=480p monoFramerate:=10 \
      publish_urdf:=false &
    ros2 launch jetson_camera jetson_camera_launch.py &
    wait; wait'
docker logs -f pilsbot-camera                          # Ctrl+C leaves it running
docker stop -t 30 pilsbot-camera && docker rm pilsbot-camera
```

Check from `pilsbot-humble` with `ros2 topic list` that the camera topics arrive. Foxy and Humble talk over DDS for these message types (ADR 0003). Both containers must use the same `ROS_DOMAIN_ID`.

During the transition, the `camera` group of the Humble `recording.yaml` lists the Foxy OAK topics ([pilsbot_bringup#7](https://github.com/pilsbot/pilsbot_bringup/pull/7)), so `log_kohl.launch.py` with the `camera` group records them from the Humble stack container:

- `/color/video/image/compressed` and `/color/video/camera_info` (OAK)
- `/front_camera/image_raw/compressed` and `/front_camera/camera_info` (CSI camera, already the Humble names, [ADR 0013](docs/adr/0013-camera-and-point-cloud-pipeline.md)). The Foxy camera container publishes `/image_raw/compressed` and `/camera_info` instead, so bags recorded during the transition have no CSI stream.

The `compressed` topic exists only if `compressed_image_transport` is installed in the Foxy camera image. Check on the robot, with the camera container running: `ros2 topic list | grep -E 'compressed|camera_info'` in `pilsbot-humble`. If it is missing, the bags hold only the `camera_info` topic. The `compressed` plugin encodes JPEG on the camera container's CPU, only while the recorder subscribes; raw images and depth are not recorded. When the camera container moves to Humble, the OAK entries change to the Humble camera node's names.
