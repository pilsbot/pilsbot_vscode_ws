# Humble is primary; Foxy is kept alive through backports, not dual-distro code

All Pilsbot repositories get a `humble` and a `foxy` branch. Repositories that used `foxy-devel` rename it to `foxy`. Repositories that used `main`/`master` branch both lines from there, and later move main/master forward to `humble`. New work lands on the Humble line. Substantial improvements that do not depend on the distro are cherry-picked to the Foxy line: ROS-free cores, bug fixes, the frame re-root, and the robot profile. The ros2_control adapters and launch-API changes stay Humble-only.

We rejected making every package build on both distros (`#if` on ros2_control versions). The hardware and controller APIs changed completely between Foxy and Humble, so this would roughly double the work in the code that is riskiest to change. Backporting stays cheap because the logic worth backporting is deliberately kept free of ROS.

Only our own code is ported. Third-party packages are consumed as their upstream or the Humble binaries provide them.
