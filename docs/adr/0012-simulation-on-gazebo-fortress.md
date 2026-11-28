# The simulation runs on Gazebo Fortress and goes through the robot's own launch path

On Foxy the simulation was a separate world. It ran on Gazebo Classic with its own launch file, its own controller config (`acker_diff_controller_sim.yaml`, with other PID gains and limits, its own copy of the geometry and a differently named broadcaster), and a URDF flag `use_fake_hardware` that defaulted to `true` and then selected Classic's `GazeboSystem`. A result in that sim said little about the robot. Now the simulation runs on **Gazebo Fortress** (`ros_gz` and `ros-humble-gz-ros2-control` from apt, physics engine DART, the default), and it starts the robot's stack through the same launch files, controller config and start sequence as the robot. Gazebo Classic is removed from the code (URDF, launch files, controller config), and the desktop devcontainer installs Fortress and `gz_ros2_control` from the ROS apt repo (see Consequences).

One seam selects what is behind the `ros2_control` interfaces: the argument `hardware:=real|gazebo` (later `kinematic`). It exists in the URDF (`pilsbot_description`) and in the launch files of `pilsbot_driver` and `pilsbot_bringup`, which pass it through every include together with `use_sim_time`. `pilsbot_simulation`'s `sim.launch.py` starts `gz sim`, spawns the robot from `robot_description`, bridges `/clock` and the cameras with `ros_gz_bridge` (since milestone 2 the images go through `ros_gz_image`'s `image_bridge`, ADR 0013), and includes `pilsbot_bringup`'s `pilsbot.launch.py` with `hardware:=gazebo use_sim_time:=true`.

- **URDF:** `hardware` has no usable default. An empty or unknown value stops xacro with a message that names the argument (ADR 0009). `real` selects `pilsbot_driver/PilsbotDriver` with the hoverboard and Head MCU sensors, exactly as before. `gazebo` selects `gz_ros2_control/GazeboSimSystem` and adds the Fortress `<gazebo>` block: the system plugin `gz_ros2_control::GazeboSimROS2ControlPlugin` and the camera sensors. With `real` the URDF has no `<gazebo>` element.
- **Launch:** with `gazebo`, `ros2_control_node` and its Shutdown-on-exit handler are not started, because the controller manager runs inside Gazebo's plugin, and GNSS and lighting are not started either. robot_state_publisher, the spawners, the hardware activator, teleop and foxglove_bridge are the robot's launch code, with `use_sim_time`.
- **Controller config:** the plugin gets two `<parameters>` files: the real `pilsbot_control/config/acker_diff_controller.yaml`, then the overrides file that `pilsbot_driver`'s `pilsbot.launch.py` writes from the robot profile (geometry and `use_sim_time`), passed to xacro as `controller_overrides:=<path>`. `acker_diff_controller_sim.yaml` is deleted. If the real gains misbehave in the sim, the sim model is fixed, not the controller.
- **Passive steering:** the steering pivot is free and the two front wheels are driven, so the steering angle emerges from the wheel speed difference under the real controller's steering loop, as on the robot (glossary: passive steering). There is no sim-only controller and no position-controlled pivot.
- **Topics and frames:** the robot's. `odom` → `base_footprint` from the controller, the URDF's OAK optical frames, the camera topic names of the Humble `pilsbot_depthai` node, and `AckermannDriveStamped` on `/pilsbot_velocity_controller/cmd_vel` from `teleop_acker_joy`.

## Verified in the spike

The spike ([pilsbot_simulation#1](https://github.com/pilsbot/pilsbot_simulation/issues/1), branch `spike/fortress`) checked this on Fortress with `gz_ros2_control` 0.7.21 on a laptop (Intel HD 520) on 2026-11-27:

- The plugin loads both `<parameters>` files. The controller ran with the profile geometry (wheel separation 0.62, wheelbase 0.67, wheel radius 0.125) and the real PID (Kp 2.0), and `use_sim_time` was true on every node of the stack. The 11 XML comments in the URDF do no harm, because the plugin reads `robot_description` from robot_state_publisher.
- Passive steering on DART with the real PID, no damping or friction on the pivot and wheel friction mu = 1: commanded steering angles at standstill were reached within 0.001 rad, and within 0.01 rad while driving at 0.4 m/s. After 27.6 m of straight driving and full circles left and right at ±0.4 rad, odometry was 0.05 m off the ground truth. Bullet was not needed.
- The OAK colour, mono, depth and point-cloud topics come through `ros_gz_bridge` with their `camera_info` and the robot's frame_ids. Headless (`gz sim -s --headless-rendering`) the cameras render through EGL. With all cameras on, the real-time factor is 0.23–0.35 headless and about 0.6 with the GUI.
- The `ros2_control` sensors `hoverboard_api` and `head_mcu` are emitted only for `real`, because they are `PilsbotDriver` state interfaces.

## Interaction with the start sequence (ADR 0007)

The spawners load both controllers `--inactive` and the hardware activator activates them, as on the robot. `gz_ros2_control` activates the hardware itself when Gazebo starts and ignores `hardware_components_initial_state`, so in the sim the activator never activates hardware and only takes its "activate controllers" branch. Its 5 s period counts in sim time: at a real-time factor of 0.3 the controllers became active about 25 s of wall time after the launch.

Supervision (ADR 0011) has no counterpart in the sim. `sim.launch.py` ends the launch when Gazebo exits, and Gazebo runs with the `exec` launch prefix, so a signal to `ros2 launch` alone also stops the Gazebo server.

## Considered options

- **Stay on Gazebo Classic:** rejected. Classic is end of life since January 2025 and not packaged for the Ubuntu that Jazzy runs on, so every Classic line written now would be migration work later.
- **Gazebo Harmonic on Humble:** rejected. Its packages conflict with `ros-humble-ros-gz`, and `gz_ros2_control` for that pairing exists only from source. Fortress is the Gazebo version paired with Humble and is supported until May 2027, like Humble ([Gazebo releases](https://gazebosim.org/docs/latest/releases)). It has binaries for everything the sim needs. The step to Harmonic or Jetty comes with Jazzy and is mostly a rename (`ign` → `gz`).
- **A sim-only controller or a position-controlled steering pivot:** rejected. It would drive well in the sim and say nothing about passive steering, which is what the real controller has to get right.
- **A separate simulation launch with its own node set:** rejected. The sim would drift from the robot as the Foxy sim did. One argument through the existing launch files keeps the difference in one place.
- **Keep `use_fake_hardware` with a safe default:** rejected. A boolean cannot grow a third mode, and any default hides a forgotten argument: with the old `true` default a caller that forgot the flag silently got the simulation plugin.
- **Physics without Gazebo (`hardware:=kinematic`):** postponed. No standard `ros2_control` component models passive steering, so it needs its own small hardware plugin.

## Consequences

- Milestone 1 (driving) is the scope: no GNSS, no fault emulation (hoverboard silence, NaN steering), no kinematic mode and no citysim. Those are later milestones in the spec ([pilsbot_vscode_ws#28](https://github.com/pilsbot/pilsbot_vscode_ws/issues/28)).
- The desktop devcontainer (`.devcontainer/desktop/Dockerfile`) builds from `althack/ros2:humble-desktop`, which has no Gazebo, and installs Fortress, `ros_gz` and `gz_ros2_control` from the ROS apt repo ([pilsbot_vscode_ws#36](https://github.com/pilsbot/pilsbot_vscode_ws/issues/36)). It used `althack/ros2:humble-gazebo`, which by then also carried Fortress (`ros-humble-ros-gz`, through the OSRF repo) and no Classic, but not `gz_ros2_control`.
- Every caller of `pilsbot.urdf.xacro` must pass `hardware`. The driver launch and the legacy-log converter pass `hardware:=real`.
- The wheel inertias are solid cylinders computed from the profile's wheel radius, in both modes. The old placeholders of 1.0 kg m² turned the chassis about 7° when steering hard at standstill in the sim. Nothing on the robot reads them.
- With `hardware:=gazebo` the driver launch ignores `runtime_config_package`: the controller config always comes from `pilsbot_control`, and the launch logs that it ignored a non-default value.
- `/dynamic_joint_states` in the sim carries only the joints, not the hoverboard and Head MCU sensor values.
- The sim's cameras differ from the robot's: depth is 32FC1 in metres (the robot: 16UC1 in mm), the mono images are raw (the robot publishes only `image_rect/compressed`), and the sim always publishes the decoded colour image `/camera/color/image_raw` (the robot only with `enable_raw_decode:=true`). Milestone 2 drops Gazebo's `/camera/stereo/points` and gives the CSI camera the robot's names and an optical frame (ADR 0013).
- Starting or stopping with the steering at 1 rad or more makes the wheels slip in the sim, and odometry then loses tens of degrees of yaw. Steady driving at those angles tracks. The launch test uses 0.5 rad or less.
- The controller's `odom` origin is the front pivot's start position (ADR 0002), so `base_footprint` starts one wheelbase behind it. Tests check relative motion.
- The sim runs below real time with the cameras on. A headless drive test takes minutes, and it skips itself when Fortress is missing.
