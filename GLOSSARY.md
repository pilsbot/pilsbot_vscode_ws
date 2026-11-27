# Pilsbot

Pilsbot is a hobby sidewalk robot on a hoverboard drivetrain with a passively steered front axle. This glossary covers the whole workspace, including the robot, its software lines, and its recorded data.

## Vehicle

**Front axle**:
The steerable axle that carries the two driven hoverboard wheels and pivots relative to the chassis.
_Avoid_: steering axle (when meaning the whole axle), drive axle

**Rear axle**:
The rigid, unpowered axle fixed to the chassis.

**Rear axle centre**:
The midpoint of the rear axle, which is the robot's reference point for pose, odometry, and planning.
_Avoid_: base (unqualified), robot origin

**Wheelbase**:
The distance from the front axle's pivot to the rear axle centre.

**Steering angle**:
The angle between the front axle and the chassis, measured at the pivot.
_Avoid_: steering position, pot value (for the calibrated angle)

**Steering rate**:
How fast the steering angle changes.
_Avoid_: steering angle velocity (ambiguous, see steering authority)

**Steering authority**:
How strongly the controller actively turns the front axle towards the commanded steering angle; zero means passive steering only. The gamepad mappings and Ackermann commands carry it in the field `steering_angle_velocity`.
_Avoid_: steering angle velocity (ambiguous, see steering rate)

**Passive steering**:
Turning the front axle by driving its two wheels at different speeds, since no motor acts on the pivot.

**Acker-diff steering**:
Pilsbot's drive scheme, which accepts Ackermann commands (speed and steering angle) and realises them through passive steering.
_Avoid_: diff drive, Ackermann drive (alone)

**Endstop**:
A switch marking the mechanical limit of the steering angle on either side.

**Hoverboard**:
The repurposed hoverboard controller board and its two hub-motor wheels, which together drive the front axle.

**Head MCU**:
The microcontroller on the front axle that reads the steering potentiometer and the endstops, and presses the hoverboard's power button.

**Power toggle**:
One simulated press of the hoverboard's power button, which switches the hoverboard on if it is off and off if it is on; nobody can tell which beforehand.
_Avoid_: power on, power off, switching on (for the press itself)

**Hardware activator**:
The node that brings the Pilsbot hardware and its controllers into operation whenever they are not, at startup and after every drop-out.
_Avoid_: watchdog, supervisor

**Enable button**:
The gamepad button that must be held for teleop to drive the robot; releasing it stops the robot (dead-man switch).
_Avoid_: deadman, safety button

**Turbo button**:
The gamepad button that drives with the faster turbo scaling while held, with or without the enable button; releasing it stops the robot like the enable button.
_Avoid_: snail button

**Robot profile**:
The single description of one physical Pilsbot: geometry, steering calibration, the ports of its devices, and its gamepad mapping. The GNSS receiver is not in it yet (ADR 0009).
_Avoid_: config, robot yaml

**StVO lighting**:
Headlight, turn signal, brake, and hazard behaviour that follows German road traffic rules (StVO).
_Avoid_: indicators (for the whole set), LEDs

## Perception

**OAK**:
The OAK-D Lite camera, which provides colour, stereo depth, and on-camera neural inference.
_Avoid_: depthai (for the device), Luxonis camera

**Drivability map**:
A robot-local map that labels the ground ahead as drivable sidewalk, road, or not drivable.
_Avoid_: costmap (for the semantic layer), segmentation map

## Software lines

**Humble line**:
The primary development line of all Pilsbot repositories, targeting ROS 2 Humble.

**Foxy line**:
The maintained legacy line targeting ROS 2 Foxy, which receives backports of substantial distro-independent improvements.
_Avoid_: old branch, foxy-devel

**Camera container**:
The Nano container with Jetson L4T libraries that owns both cameras: the OAK with its hardware-accelerated decoding, and the CSI camera.

**Stack container**:
The Nano container that runs everything else from Humble binary packages.

## Frames

**`odom`**:
The world-fixed odometry frame, whose origin is where the front axle stood when odometry was last reset.
_Avoid_: odom_raw

**`base_footprint`**:
The rear axle centre on the ground, which is the frame odometry tracks in `odom`.
_Avoid_: base_link (for the tracked frame)

**`base_link`**:
The rear axle centre at wheel-axle height, one wheel radius above `base_footprint`.

## Data

**Kohlfahrt**:
A real outing with the robot, usually in public.
_Avoid_: test drive (for an outing)

**Kohl mode**:
The robot's configuration for a Kohlfahrt: the stack with gamepad teleop and recording, and the cameras at a reduced data rate (OAK at 480p and 10 fps on the Foxy line).

**Kohlfahrt log**:
A bag recorded during a Kohlfahrt, used as raw material for datasets.

**Legacy log**:
A Kohlfahrt log recorded before the robot reference point moved to the rear axle centre, which must go through the legacy-log converter before it is used with current frames.

**Legacy-log converter**:
The tool that turns a legacy log into a Kohlfahrt log with current frames and topics.
_Avoid_: bag migration, re-rooting (for the whole tool)
