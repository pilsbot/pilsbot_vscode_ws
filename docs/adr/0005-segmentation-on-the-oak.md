# Sidewalk segmentation runs on the OAK's neural accelerator first

The segmentation network for the drivability map runs on the OAK-D Lite's Myriad X, inside the camera node's pipeline. This leaves the Nano's CPU and GPU free for SLAM and control. TensorRT on the Nano, in the camera container, is the fallback if the Myriad X proves too slow or the model needs unsupported layers. Picking the model is still open.

## Consequences

- Models are limited to what OpenVINO can compile to a Myriad X blob (FP16, restricted op set), so they will be small mobile-sized networks.
- Training images extracted from Kohlfahrt logs must be preprocessed exactly as the camera preprocesses the network's input. Recorded frames are MJPEG-compressed, while the on-camera network sees uncompressed ISP frames.
