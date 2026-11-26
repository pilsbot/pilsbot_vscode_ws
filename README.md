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
