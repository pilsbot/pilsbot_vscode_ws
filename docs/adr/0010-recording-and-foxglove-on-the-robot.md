# Kohlfahrt logs are split MCAP files on the SSD; Foxglove on the robot is read-only

The stack container records Kohlfahrt logs with `pilsbot_bringup`'s `log_kohl.launch.py`, which `kohlfahrt_teleop_and_log.launch.py` starts next to the driving stack. The topics come from `config/recording.yaml` in groups (`robot_state`, `logs`, `commands`, `gnss`, `camera`), so a short test drive can leave the camera out with `groups:=...`. Recordings are MCAP without compression, split every 300 s:

- **MCAP:** Foxglove opens it directly, a file cut off by a crash stays readable, and it is rosbag2's default in later distros (ADR 0006). The Foxy logs were SQLite.
- **No compression:** camera frames are already JPEG from the OAK's encoder, and the Nano's CPU is needed elsewhere. Decoded images are never recorded.
- **Split files:** a crash or a full disk loses at most one file. Humble's rosbag2 writes latched topics only into the first file, so `static_data_republisher` re-sends `/tf_static` and `/robot_description` every 10 s, and every file opens on its own.

Bags go to `/workspaces/bags`, the bind mount of the external SSD. The recorder does not start if that directory is on the same filesystem as `/` or `/etc/hostname`, or if less than 10 GB is free there. Without the SSD it would fill the Nano's SD card. `check_output_dir:=false` records anyway, with a warning. Bag names get a random suffix, because the Nano has no RTC and dates repeat after a reboot.

Recording never stops the robot. A refused output directory or a recorder that exits prints a `!!` banner, and driving continues.

`foxglove_bridge` runs in the stack container for live viewing (port 8765), with only the `connectionGraph` and `assets` capabilities, and a client topic whitelist that matches nothing. The bridge has no authentication. With its defaults, anyone on the network at a public outing could publish `cmd_vel`, switch controllers, or change parameters, which bypasses the enable button. `foxglove_capabilities:=all` (or a list) enables writing for development and prints a warning banner.

## Considered options

- Record the cameras in the camera container, next to the frames: rejected, also for the transition. The JPEG streams are small enough for DDS (about 4 MB/s, ADR 0004), and one recorder keeps one bag per outing.
- Foxglove with the upstream defaults (all capabilities): rejected for the reason above. Development setups opt in explicitly.

## Consequences

- Without the SSD mounted, nothing is recorded. The launch output shows a `NOT RECORDING` banner.
- Foxglove cannot publish, call services, or edit parameters by default. Its teleop and parameter panels stay inactive.
- Live Foxglove clients see `/robot_description` again every 10 s while recording.
- During the camera transition (ADR 0003) the `camera` group lists the topic names of the Foxy camera container. It changes to the Humble camera node's names when that container moves to Humble.
- New logs contain `/dynamic_joint_states` instead of `/hoverboard_api` and `/head_mcu` (ADR 0006), and `/rosout` in the `logs` group.
