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
The microcontroller on the front axle that reads the steering potentiometer and the endstops.

**Robot profile**:
The single description of one physical Pilsbot: geometry, steering calibration, device ports, and joystick mapping.
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
The Nano container with Jetson L4T libraries that owns the OAK and its hardware-accelerated decoding.

**Stack container**:
The Nano container that runs everything else from Humble binary packages.

## Data

**Kohlfahrt log**:
A bag recorded during a real outing with the robot, used as raw material for datasets.

**Legacy log**:
A bag recorded before the robot reference point moved to the rear axle centre, which must be translated before it is used with current frames.
