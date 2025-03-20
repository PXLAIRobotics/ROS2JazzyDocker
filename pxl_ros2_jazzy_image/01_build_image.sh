#!/bin/bash
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running this script on macOS..."
    docker build \
           --platform linux/amd64 \
           --build-arg UID=$UID \
           -t pxl_ros2_jazzy:latest .
else
    echo "Running this script on Windows/Linux..."
    docker build \
           --build-arg UID=$UID \
           -t pxl_ros2_jazzy:latest .
fi
