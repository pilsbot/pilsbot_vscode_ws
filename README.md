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

1. Import the sources and install their dependencies with `./setup.sh` (desktop default), or pass the repos files for your target, e.g. `./setup.sh src/ros2.repos`. The tasks `Terminal->Run Task..->setup` and `import from workspace file` do the same.
2. Run the build task with `Ctrl+Shift+B`, or `./build.sh`. Set `BUILD_TYPE` to override the default `RelWithDebInfo`.

### Launch the simulation

To test a successfull configuarion and build of the workspace you can start the Pilsbot
simulation. You have two options to do so.

1. Open a terminal in your workspace and type: `ros2 launch pilsbot_simulation pilsbot.launch.py`
2. Press `Ctrl+Shift+P` search for `ROS: Run a ROS launch file (roslaunch)`, type the package name `pilsbot_simulation`, choose a launch file e.g. `pilsbot.launch.py` and press `Enter` again to skip defining additional launch arguments.

Congratulations, you now have a setup workspace to develop on the Pilsbot platform! 🎉

If any issues occur during the setup process, do not hesitate to open an issue, so we can
fix the problem as soon as possible.

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

The Foxy camera topics (`/color/video/image`, `/stereo/depth`, `/image_raw`, ...) are not the ones in the `camera` group of the Humble `recording.yaml`, which expects the Humble `mjpeg_node` (`/camera/color/image_raw/compressed`, ...). The CSI camera's topic names under Humble (`jetson_camera` with its sub-node `camsub`) are also unconfirmed until the robot test. Until both are settled, Humble's `log_kohl.launch.py groups:=camera` records nothing from the Foxy cameras; record them in the camera container instead if you need them.
