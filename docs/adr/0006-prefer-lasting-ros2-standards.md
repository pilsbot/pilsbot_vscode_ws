# Prefer ROS 2 standards that outlive Humble over custom equivalents

Where Humble offers a standard mechanism that persists in later distros, Pilsbot adopts it, even when this changes our own topics or recorded data. Custom code that only re-implements such a mechanism is removed, not ported.

First application: the custom `pilsbot_sensor_broadcaster` is removed. The upstream `joint_state_broadcaster` publishes the hoverboard and Head MCU `<sensor>` state interfaces on `/dynamic_joint_states` (`control_msgs/DynamicJointState`, verified with Humble 2.54 and mock hardware on 2026-11-26).

## Considered options

- Port the custom broadcaster and keep `/hoverboard_api` and `/head_mcu`: rejected. It would keep a whole controller to maintain on every distro only to preserve topic names.

## Consequences

- New recordings contain `/dynamic_joint_states` instead of `/hoverboard_api` (`pilsbot_driver_msgs/HoverboardAPISensors`) and `/head_mcu` (`pilsbot_driver_msgs/SteeringAxleSensorsStamped`).
- The legacy-log converter (ADR 0002) also maps those two legacy topics to `/dynamic_joint_states`, so datasets see one format across old and new logs.
- The steering calibration script also reads the Head MCU values from `/dynamic_joint_states`, so it works while the ros2_control driver owns the Head MCU. The standalone `head_mcu_node` keeps publishing `/head_mcu` for calibration without the driver.
