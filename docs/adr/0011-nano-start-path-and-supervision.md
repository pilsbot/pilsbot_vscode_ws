# systemd restarts the whole stack container, and the motors are switched off between runs

On the robot, `pilsbot_stack.service` from [useful-scripts](https://github.com/pilsbot/useful-scripts) (`Restart=always`, `RestartSec=1`) runs `startall.bash`:

1. `enable_motors.bash` sets the motor outputs of the I2C port expander.
2. `setup_serials.bash` creates the device links `/dev/ttyHoverboard`, `/dev/ttyHeadMCU`, and `/dev/ttyGPS`.
3. `start_latest_pilsbot_stack.sh` `exec`s `docker run --rm` of the stack container, whose command `exec`s `ros2 launch pilsbot_bringup kohlfahrt_teleop_and_log.launch.py` (Kohl mode).
4. `disable_motors.bash` clears the motor outputs. A trap runs it on every exit of `startall.bash`, including a failed step or a non-zero exit of the container.

Inside the launch, nothing restarts `ros2_control_node`. If it exits, for any reason, the whole launch shuts down (`OnProcessExit` → `Shutdown`). The container then exits, the motors are switched off, and systemd starts everything again a second later with a fresh controller manager. Failures below that level are handled where they happen:

- Hardware drop-outs: the hardware activator (ADR 0007).
- Devices that are missing at startup or vanish later: the lighting bridge and the GNSS driver respawn every 5 s until their port is there.
- A recorder that exits: a banner, and driving continues (ADR 0010).

The camera container is not part of this service. It drives nothing, so a camera failure must not restart the driving stack, and the stack restarting must not restart the cameras.

| Container | Builds | Started by |
|---|---|---|
| Stack | `src/ros2.repos` in `~/pilsbot_humble_ws` | `pilsbot_stack.service` (target); by hand for now, see below |
| Camera | `src/jetson-camera.repos` (dustynv image, ADR 0003); during the transition the Foxy workspace as built | by hand (README) |

## Considered options

- `respawn=True` on `ros2_control_node`: rejected. The motors would stay enabled across the restart, and a restart loop would hide inside the launch output instead of showing in `systemctl status`.
- A Docker restart policy on the container: rejected. It skips `disable_motors.bash` and `enable_motors.bash` and the serial setup.

## Consequences

- A crash of the controller manager costs a full stack restart of a few seconds plus the activator period, and the odometry restarts at the origin.
- `disable_motors.bash` is the only thing that switches the motors off when `ros2_control_node` dies without its destructor running, for example on SIGKILL (ADR 0008).
- Until the service starts the Humble image, it still runs the Foxy stack. The Humble stack container (`pilsbot-humble`) is started by hand with `docker exec` (README). In that setup an exit of `ros2_control_node` only ends the `ros2 launch`: the container stays up and the motors stay enabled.
