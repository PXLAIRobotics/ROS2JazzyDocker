#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running this script on macOS..."
    docker run                    \
           --rm                   \
           --platform linux/amd64 \
           --name pxl_jazzy       \
           --hostname pxl_jazzy   \
           -it                    \
           --privileged           \
           --shm-size=512m        \
           -p 6901:6901           \
           -e VNC_PW=password     \
           pxl_ros2_jazzy:latest
else
    echo "Running this on Linux or Windows"
    docker run                    \
           --rm                   \
           --name pxl_jazzy       \
           --hostname pxl_jazzy   \
           -it                    \
           --privileged           \
           --shm-size=512m        \
           -p 6901:6901           \
           -e VNC_PW=password     \
           pxl_ros2_jazzy:latest
fi
