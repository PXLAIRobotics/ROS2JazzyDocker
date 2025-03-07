#!/bin/bash
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running this script on macOS..."
    docker build \
           --platform linux/amd64 \
           -t pxl_ros2_jazzy:latest .
else
    echo "Running this script on macOS..."
    docker build \
           -t pxl_ros2_jazzy:latest .
fi
