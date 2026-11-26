# We keep our own OAK camera node instead of depthai_ros_driver

`pilsbot_depthai` keeps its own nodes (`rgb_stereo_node`, `h265_node`, `mjpeg_node`) and does not move to upstream `depthai_ros_driver`. The OAK encodes colour (1080p, ISP-scaled to 1280×720) and the mono pair as MJPEG on the camera. On the Nano these are decoded by a GStreamer pipeline (`appsrc → [jpegparse] → nvjpegdec | nvv4l2decoder → nvvidconv → appsink`), with software `jpegdec`/`videoconvert` as the fallback. Moving uncompressed frames over USB and handling them on the Nano's CPU cost too much. Getting hardware decoding to work took substantial effort, and upstream has no equivalent for the Nano.

## Verified state (2026-11-26, Nano on L4T R32.7.2, Foxy container)

Run as `ros2 launch pilsbot_depthai mjpeg_node.launch.py nvdecoder:=nvv4l2decoder enable_raw_decode:=true` from `feature/h265-encoded-transport` @ adc8a64:

- `nvv4l2decoder` (not `nvjpegdec`) is the decoder in use. The NVIDIA GStreamer elements are provided by `--runtime=nvidia`; copying `jetson_multimedia_api` into the image is not needed.
- Colour 1280×720 MJPEG at 30 fps (about 3.3 MB/s), each mono stream 400p at 15 fps (about 0.39 MB/s), decoded colour `Image` at about 27 fps.
- The node uses about a third of one CPU core while idle, rising to about half a core with a subscriber on the decoded image. The rest of the Nano stays about 85% idle.
- A Humble desktop (FastDDS, Wi-Fi) receives the streams from the Foxy/CycloneDDS container at full rate.

## Consequences

- Only one process can open the OAK. Depth, encoders, and any on-camera neural network must share this node's pipeline.
- `nvjpegdec` cannot share a process with code that uses the system libjpeg, which includes OpenCV's image decoding (see commit f40023b). Whether this also applies to the `nvv4l2decoder` path in use has not been checked, so composing OpenCV-heavy consumers into the decoder's process stays an open question.
- The GStreamer pipeline is known to be brittle. Its build and runtime dependencies must be scripted in the camera container's Dockerfile, not just remembered.
- The `foxy-devel` → `foxy`/`humble` branches must absorb `feature/h265-encoded-transport`, and all nodes must move to the Humble-era depthai-core API (`CameraBoardSocket::CAM_A/B/C`).
