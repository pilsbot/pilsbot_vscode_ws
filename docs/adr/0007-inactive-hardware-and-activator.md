# The hardware starts inactive, and a hardware activator keeps it active

Humble's `ros2_control_node` aborts when a hardware component fails to activate at startup ("Failed to set the initial state of the component"). On Foxy a missing hoverboard or Head MCU cost only driving. On Humble it took teleop, GNSS, lighting, Foxglove, and recording down with it. So the controller manager now starts `PilsbotSystem` inactive (`hardware_components_initial_state.inactive`), and the spawners load both controllers with `--inactive`. The hardware activator (`pilsbot_driver`'s `hardware_activator`) brings them into operation. Every 5 s it asks the controller manager for the hardware's state. If the hardware is not active, it activates it. Once the hardware is active, it configures and activates any controller that is not. It does this at startup and again whenever the hardware drops out, and it logs a still-failing activation about once a minute. Each service call has a deadline (`call_timeout`, 30 s), so a hung or restarted controller manager cannot block it for good. It gives up only when the hardware is `finalized`, because that state cannot be left without restarting the controller manager.

## Considered options

- Respawn `ros2_control_node` until the devices answer: rejected. Every respawn would also restart the controllers and lose the odometry, and it would hide the cause in a restart loop. Supervision of the controller manager itself is the systemd service's job (ADR 0011).
- Make activation always succeed and report missing devices later: rejected. The controller would then run on interfaces with no device behind them, and the activator would have nothing to act on.

## Fault handling

The activator only handles lifecycle failures. Faults while the hardware is active stay inside the driver and the controller, so they never cost an activation cycle:

| Fault | Driver | Controller |
|---|---|---|
| Hoverboard silent for 1 s | NaN steering angle, power toggle requested (ADR 0008), `read()` OK | halts the wheels |
| Implausible hoverboard sample (EMI) | sample dropped, last plausible speeds kept, `read()` OK | carries on |
| Serial read error | NaN steering angle for that cycle, `read()` OK | halts the wheels for that cycle |
| Head MCU lost | NaN steering angle and endstops at once, one reconnect attempt per second until it is back, `read()` OK | halts the wheels |
| Device missing at activation | activation fails after its retries | stays inactive; the activator retries |

"Halts the wheels" means the controller writes 0 to both wheel commands and restarts its ramp and steering loop. When valid data returns, it ramps up from standstill. It does not resume at the speed it had before the fault.

## Consequences

- The hardware and the controllers come up at least one activator period (5 s) after the launch, not with it. `/odom` and `/joint_states` start late too.
- `read()` and `write()` return OK without touching anything until `on_activate` succeeded, because Humble calls them on inactive hardware as well.
- Humble handles a `read()` or `write()` error with `on_error` and leaves the hardware unconfigured without `on_deactivate`. The driver therefore closes its ports and joins the Head MCU thread in `on_error` and `on_cleanup` too, so the next activation leaks nothing.
- `read()` and `write()` return ERROR only when the hoverboard port is closed while the hardware is active, which only a re-activation can fix. A silent device is deliberately not an error, because the power toggle and the Head MCU reconnect need the hardware to stay active.
