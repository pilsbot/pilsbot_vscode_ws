# Pilsbot ROS2 Workspace

This repository contains a preconfigured workspace for development of the Pilsbot platform. The branch `humble` is the primary development line. The branch `foxy` is the maintained legacy line, which receives backports of substantial improvements (see [docs/adr](docs/adr)).

One branch serves every target. The targets differ only in which repos files they import and which devcontainer they use:

| Target | Devcontainer | Repos files |
|---|---|---|
| Desktop development and simulation | `.devcontainer/desktop` | `src/ros2.repos`, `src/desktop.repos` (default) |
| Jetson Nano, everything except the camera | `.devcontainer/jetson-stack` | `src/ros2.repos` |
| Jetson Nano, OAK camera with hardware decoding | `.devcontainer/jetson-camera` | `src/jetson-camera.repos` |

The Nano runs two containers side by side; see [ADR 0003](docs/adr/0003-two-container-nano-runtime.md). Project vocabulary lives in [GLOSSARY.md](GLOSSARY.md).

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

1. Import the sources and install their dependencies with `./setup.sh` (desktop default), or pass the repos files for your target, e.g. `./setup.sh src/ros2.repos`. The tasks `Terminal->Run Task..->setup` and `import from workspace file` do the same and ask for the target.
2. Run the build task with `Ctrl+Shift+B`, or `./build.sh`. Set `BUILD_TYPE` to override the default `RelWithDebInfo`.

### Check the build

The simulation (`pilsbot_simulation`) is not ported to Humble yet, so it is no smoke test for now. Check the build instead:

```
source install/setup.bash
ros2 pkg executables pilsbot_driver   # lists hardware_activator
xacro $(ros2 pkg prefix pilsbot_description)/share/pilsbot_description/urdf/pilsbot.urdf.xacro > /dev/null
```

`./build.sh` passes extra arguments to `colcon build`, e.g. `./build.sh --packages-select pilsbot_driver` or `./build.sh --packages-skip <name>`.

If any issues occur during the setup process, do not hesitate to open an issue, so we can
fix the problem as soon as possible.

## On the Jetson Nano

The Humble stack container lives next to the Foxy stack, which stays as it is: Foxy in `~/pilsbot_vscode_ws` (container `pilsbot_stack`, started by `pilsbot_stack.service` from [useful-scripts](https://github.com/pilsbot/useful-scripts)), Humble in a second workspace `~/pilsbot_humble_ws` with the image `pilsbot/humble-stack` and the container `pilsbot-humble`. Never run both stacks at the same time; stop the service first (`sudo systemctl stop pilsbot_stack`).

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

```
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
./setup.sh src/ros2.repos
./build.sh --parallel-workers 1   # the 4 GB Nano runs out of memory with parallel builds
```

Why the flags:

- `--group-add`: `--privileged` lets the container open devices, but the user `ros` still needs file permissions. Humble's `joy_node` (SDL) reads the gamepad from `/dev/input/event*` (`root:input`, mode 0660), Foxy read the world-readable `/dev/input/js0`. The port expander uses `/dev/i2c-*` (group `i2c`). The gids must be the host's, which differ from the image's, so they are looked up on the host. Check that both `getent` calls print a line; `ls -ln /dev/input/event* /dev/i2c-*` shows the gids the devices really use.
- `-v /run/udev:/run/udev:ro`: SDL learns about gamepads that connect later through udev.
- `--mount` instead of `-v` for the bags: it refuses to start when the SSD is not mounted. `-v` would silently create an empty, root-owned `/media/externSSD/bags` on the Nano's root file system and fill it with recordings. Without the SSD, point `source=` at an existing directory such as `~/pilsbot_bags`.

The VS Code devcontainer `.devcontainer/jetson-stack` uses the same flags. For `--group-add` it reads `PILSBOT_INPUT_GID` and `PILSBOT_I2C_GID` from the environment VS Code was started in:

```
export PILSBOT_INPUT_GID=$(getent group input | cut -d: -f3)
export PILSBOT_I2C_GID=$(getent group i2c | cut -d: -f3)
```

The camera container (`.devcontainer/jetson-camera`) runs as `root`, not `ros`, so it needs no group settings.

### DDS

Both containers use CycloneDDS (`RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`) on the host network, and must use the same `ROS_DOMAIN_ID` (default 0; set it with `-e ROS_DOMAIN_ID=<n>` in both, and on a laptop that runs `ros2` commands against the robot). Foxglove connects over its WebSocket (port 8765) and does not depend on DDS.

The Nano has several network interfaces (`docker0`, `l4tbr0`, `wlan0`, ...), and CycloneDDS may pick one the laptop cannot reach. If `ros2 topic list` on the laptop sees nothing from the robot, pin the interface with the shipped config by adding to `docker run`:

```
-e CYCLONEDDS_URI=file:///workspaces/pilsbot_humble_ws/.devcontainer/jetson-stack/cyclonedds.xml \
-e PILSBOT_DDS_INTERFACE=wlan0
```

Take the interface name from `ip -br addr` on the Nano. CycloneDDS refuses to start any node when the named interface does not exist, so leave this out when the robot runs without that network.

## Good to know

- all packages added to the workspace should use `https`. If you have a Github account logged in your VSCode installation, you can easily push without the need for password authentication. You will be asked to acknowledge your login once via your browser and you're good to go.
