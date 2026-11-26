# The robot reference point moves from the front axle to the rear axle centre

`base_link` used to be the front axle. The chassis and the OAK hung off the steering joint, so the camera's pose relative to `base_link` changed with every steering angle. This breaks the assumptions of visual SLAM and of the Ackermann planners. `base_link` now sits at the rear axle centre, with `base_footprint` on the ground below it. The odometry frame is renamed from `odom_raw` to `odom`.

The odometry estimator is deliberately left unchanged. Its front-axle pose is converted to the rear axle centre by a pure frame transform that uses the measured steering angle and the wheelbase. That transform is the same ROS-free function the legacy-log converter uses, so live data and translated Kohlfahrt logs agree by construction. Replacing the estimator with a bicycle model is a separate, later decision.

## Consequences

- Kohlfahrt logs recorded since Feb 2023 contain no `/tf`. A missing comma in `log_kohl.launch.py` merged it into `/stereo/camera_info/tf`. The converter rebuilds TF from the recorded `/robot_description`, `/joint_states`, and `/odom`, and writes MCAP.
- The wheelbase must be measured on the robot. The old values disagree: 0.67 in the controller config and about 0.68 in the URDF.
