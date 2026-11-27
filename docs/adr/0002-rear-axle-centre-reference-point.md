# The robot reference point moves from the front axle to the rear axle centre

`base_link` used to be the front axle. The chassis and the OAK hung off the steering joint, so the camera's pose relative to `base_link` changed with every steering angle. This breaks the assumptions of visual SLAM and of the Ackermann planners. `base_link` now sits at the rear axle centre, with `base_footprint` on the ground below it. The odometry frame is renamed from `odom_raw` to `odom`.

The odometry estimator is deliberately left unchanged. Its front-axle pose is converted to the rear axle centre by a pure frame transform that uses the measured steering angle and the wheelbase. The transform is a ROS-free function in the controller core (`acker_diff_core.cpp`). The legacy-log converter uses a Python twin of it (`pilsbot_log_tools/rear_axle.py`), and both test files check the same hand-derived values, so live data and translated Kohlfahrt logs agree as long as those tests pass. Replacing the estimator with a bicycle model is a separate, later decision.

The controller publishes the result as `odom` → `base_footprint`, and the URDF root is `base_footprint` with `base_link` one wheel radius above it. The published twist is the same pure transform applied to velocities: the chassis yaws at the front-axle yaw rate plus the steering rate, which is differenced from consecutive steering measurements. It is deliberately not the no-slip bicycle constraint. Any lateral velocity it reports at the rear axle is the estimator's inconsistency made visible, not hidden.

## Consequences

- Kohlfahrt logs recorded since Feb 2023 contain no `/tf`. A missing comma in `log_kohl.launch.py` merged it into `/stereo/camera_info/tf`. The converter rebuilds TF from the recorded `/joint_states` and `/odom` and from the *current* URDF, which it generates from the robot profile (ADR 0009). It ignores the recorded `/robot_description` and writes MCAP.
- Because the converter uses the current URDF and wheelbase, a log converted again after the wheelbase is re-measured comes out different. Converted logs are derived data: keep the originals, and convert again after a change to the profile.
- The wheelbase must be measured on the robot. The old values disagree: 0.67 in the controller config and about 0.68 in the URDF.
- The `odom` origin stays where the estimator starts: the front axle's pose at reset. `base_footprint` therefore starts one wheelbase away from the origin rather than at it. It lies exactly behind the origin on the x axis only if the steering angle δ0 at reset is zero. Otherwise it starts at (−L·cos δ0, −L·sin δ0) with heading δ0, for wheelbase L.
- The stock diff-drive fallback config estimates the front axle, so it labels its odometry `front_axle` and publishes no TF.
