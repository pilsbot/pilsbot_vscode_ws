# The Jetson Nano runs two Humble containers: an L4T camera container and a stock stack container

The Nano is limited to L4T r32 (Ubuntu 18.04). The only Humble images that keep Jetson's hardware (GStreamer `nvjpegdec`/`nvv4l2decoder`, CUDA, TensorRT) are dusty-nv's `dustynv/ros:humble-*-l4t-r32.7.1`. They build ROS from source with gcc-8 and Python 3.6, and `apt install ros-humble-*` does not work in them. The official `ros:humble` (22.04) arm64 image has every binary package but no access to Jetson hardware. We use both:

- **Camera container** (dustynv L4T): owns the OAK and its hardware-accelerated decoding, and the CSI camera (`jetson_camera`), which needs Jetson Argus. Only this container builds depthai from source.
- **Stack container** (official `ros:humble`): ros2_control, the controllers, the driver, teleop, GNSS, localisation, navigation, foxglove_bridge, and recording, all from apt.

Both use CycloneDDS (`RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`) with `--network=host --ipc=host`.

## Considered options

- Everything in the dustynv container: rejected. ros2_control, Nav2, and rtabmap would all need source builds on gcc-8 and Python 3.6, and nav2 and rtabmap have no confirmed working build there.
- Everything in the official image: rejected. It loses the hardware decoding the camera driver depends on to stay fast.

## Transition

The camera container stays on the existing, proven Foxy image (`pilsbot/foxy-jetson`, L4T, CycloneDDS) while the stack container moves to Humble. Foxy and Humble interoperate over DDS for the camera's message types. A Humble desktop on FastDDS received the Foxy camera streams at full rate (2026-11-26, see ADR 0004). Moving the camera container to the dustynv Humble image is a separate, later step and does not block the Humble port of the rest of the stack.

## Consequences

- Full-resolution decoded frames are expensive to send between processes. Consumers of them should live in the camera container, ideally in the same process, unless measurements show the DDS copy is acceptable.
- Open: rtabmap is meant to use the OAK's full widescreen colour resolution, and it may benefit from CUDA. Both point towards running it in the camera container, which would need a source build there. To be decided with measurements in M3/M4.
- The Foxy line uses the same repos-file and devcontainer layout with the existing `pilsbot/foxy-jetson` image. The old `foxy-jetson` workspace branch, with its untracked gitlinks, is retired.
