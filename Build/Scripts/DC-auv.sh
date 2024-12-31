source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --parallel-workers $(nproc) \
    --symlink-install --event-handlers console_direct+ --base-paths src --cmake-args \
    ' -DCMAKE_BUILD_TYPE=Debug' ' -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs' \
    ' -DCMAKE_CXX_FLAGS=-Wall -Wextra -Wno-unused-parameter' ' --no-warn-unused-cli' \
    --packages-select automata_deployment_toolkit_ros2 adtr2_base adtr2_bringup adtr2_models adtr2_interfaces && \
    source install/setup.bash && ros2 launch adtr2_bringup auv.monitor.launch.py