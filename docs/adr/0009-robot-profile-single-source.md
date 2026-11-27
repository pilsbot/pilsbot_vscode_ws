# The robot profile is the single source of facts about one physical Pilsbot

Before Humble the same facts lived in several places and disagreed. The wheelbase was 0.67 in the controller config and about 0.68 in the URDF. The serial ports were hardcoded in the driver. The steering calibration existed in four versions. Now `pilsbot_description/profiles/<name>.yaml` is the only place that holds them. Launch files take `robot_profile:=<name or path>` (default `pilsbot`) and read it through `pilsbot_description.profile`. The URDF reads it with xacro, and every other consumer gets its values from one of those two:

- **Geometry** (wheelbase, front and rear track, wheel radius): the URDF, and the controller's `wheel_base_distance`, `wheel_separation`, and `wheel_radius`, which `pilsbot.launch.py` passes as a parameter file over the controller config.
- **Steering** (mechanical limit, potentiometer calibration): the URDF joint limit, and the driver and `head_mcu_node`. The driver reads the calibration from its URDF hardware parameters.
- **Device ports** (hoverboard, Head MCU, lighting board, gamepad by SDL index or name): the driver through its URDF hardware parameters, the lighting bridge, and `joy_node`.
- **Gamepad mapping**: the name of the teleop config in `pilsbot_driver/config`.

A missing or invalid value stops the launch, or the driver's `on_init`, with a message that names it. No hardcoded fallback is used.

## Scope

The profile holds facts about the robot, not tuning. PIDs, speed and acceleration limits, and the controller's soft steering limit (1.45 rad, inside the mechanical 1.58) stay with the nodes that use them, because they change when behaviour is tuned, not when the robot is rebuilt.

Not in the profile yet: the GNSS receiver. Its port (`/dev/ttyGPS`) and frame are fixed in `pilsbot_gnss_receiver`'s `u-blox.yaml`.

The simulation reads the profile like the robot does: the URDF through xacro, and the controller through the same overrides file, which reaches Gazebo's `gz_ros2_control` plugin as a second parameter file (ADR 0012). `acker_diff_controller_sim.yaml`, which carried its own copy of the geometry, is deleted.

## Considered options

- The URDF as the single source: rejected. Launch files need ports and the gamepad mapping before any URDF exists, and those are not robot geometry.
- Keep each value with its consumer and check them against each other in tests: rejected. That keeps four places to edit when the robot changes, and it only catches disagreements that someone thought to test.

## Consequences

- Re-measuring the wheelbase is one edit, and it moves the URDF, the controller, and the legacy-log converter together. Logs converted earlier keep the old value (ADR 0002).
- The SDL gamepad fields have no Foxy equivalent (ADR 0001).
