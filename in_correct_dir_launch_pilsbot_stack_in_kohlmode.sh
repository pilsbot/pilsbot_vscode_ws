#!/bin/bash
cd /workspaces/pilsbot_vscode_ws
. install/local_setup.bash
cd /workspaces/bags
ros2 launch pilsbot_bringup kohlfahrt_teleop_and_log.launch.py
