# The hoverboard's power button is pressed blind, on silence and on clean shutdown only

The hoverboard has a single power button and reports nothing about its power state except that it sends data while it is on. The Head MCU presses the button for the driver (a power toggle): pin high for 0.5 s, low for 0.5 s. Each toggle switches the hoverboard on or off, and whether it is on can only be inferred from whether its data arrives. The driver therefore toggles in exactly two situations:

- **Silence while active:** no hoverboard data for 1 s. This is how the robot normally starts, because the hoverboard is off at boot. It also switches the hoverboard back on after it was switched off by hand. The Head MCU thread performs the toggle, so the ~1 s press does not block the control loop. Requests made during a press are dropped, so the driver toggles again only if the hoverboard is still silent afterwards.
- **Clean shutdown:** `on_deactivate`, `on_cleanup`, or the driver's destructor, if the hoverboard sent data within the last second. This switches it off, as Foxy's `stop()` did.

It never toggles after `on_error`, after a failed activation, or because a port is missing. In those cases a toggle cannot help: the hoverboard's serial port exists whether it is on or not, and the activator retries within seconds (ADR 0007). A toggle there would only make the hoverboard flip state on every retry. While the Head MCU is lost, a pending request is dropped, because it could otherwise switch off a hoverboard that came back together with the Head MCU.

All of these durations are measured on the steady clock. The Nano has no RTC, and chrony, NTP, or GNSS step the system clock after boot. A forward step would fake a silence and switch the hoverboard off while driving.

## Considered options

- Track the power state in the driver and toggle only towards the wanted state: rejected. Without feedback the tracked state goes wrong the first time someone uses the button by hand, and from then on every toggle is the wrong one.
- Toggle on every fault, as the first Humble port did through `on_error`: rejected. A single EMI spike cost about 7 s of drive and two toggles.

## Consequences

- A hoverboard that is on but whose data does not arrive (for example, a broken receive line) is toggled off and on again about once a second, for as long as the data is missing. The log shows the repeated timeouts.
- A toggle needs the Head MCU. Without it, a silent hoverboard stays as it is.
- `ros2_control_node` killed hard (SIGKILL) does not toggle. The motors are switched off by the start path instead (ADR 0011).
