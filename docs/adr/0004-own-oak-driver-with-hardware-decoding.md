# We keep our own OAK camera node instead of depthai_ros_driver

`pilsbot_depthai` keeps its own nodes (`rgb_stereo_node`, `h265_node`, `mjpeg_node`) and does not move to upstream `depthai_ros_driver`. The OAK encodes colour (1080p, ISP-scaled to 1280×720) and the mono pair as MJPEG on the camera. On the Nano these are decoded by a GStreamer pipeline (`appsrc → [jpegparse] → nvjpegdec | nvv4l2decoder → nvvidconv → appsink`), with software `jpegdec`/`videoconvert` as the fallback. Moving uncompressed frames over USB and handling them on the Nano's CPU cost too much. Getting hardware decoding to work took substantial effort, and upstream has no equivalent for the Nano.

## Consequences

- Only one process can open the OAK. Depth, encoders, and any on-camera neural network must share this node's pipeline.
- `nvjpegdec` cannot share a process with code that uses the system libjpeg, which includes OpenCV's image decoding (see commit f40023b). Composing OpenCV-heavy consumers into the decoder's process is therefore not an option without further work.
- The GStreamer pipeline is known to be brittle. Its build and runtime dependencies must be scripted in the camera container's Dockerfile, not just remembered.
- The `foxy-devel` → `foxy`/`humble` branches must absorb `feature/h265-encoded-transport`, and all nodes must move to the Humble-era depthai-core API (`CameraBoardSocket::CAM_A/B/C`).
