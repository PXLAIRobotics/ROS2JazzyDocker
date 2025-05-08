#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running this script on macOS..."
    docker build \
        --build-arg USER_UID=$(id -u) \
        --build-arg USER_GID=$(id -g) \
        --platform linux/amd64 \
        -t pxl_ros2_jazzy_novnc:latest .
else
    echo "Running this script on Windows/Linux..."
    docker build \
        --build-arg USER_UID=$(id -u) \
        --build-arg USER_GID=$(id -g) \
        -t pxl_ros2_jazzy_novnc:latest .
fi
