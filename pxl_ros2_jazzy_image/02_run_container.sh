#!/bin/bash

# Detect CPU Architecture
ARCH=$(uname -m)

# Initialize an empty list (array)
DOCKER_OPTS=()
DOCKER_OPTS+=("--name=pxl_jazzy")
DOCKER_OPTS+=("--hostname=pxl_jazzy")
DOCKER_OPTS+=("--rm" "-it") 

# Check if running on ARM (Apple Silicon or ARM-based Linux)
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    DOCKER_OPTS+=("--platform=linux/amd64")
fi

# Check if nvidia-smi is available (indicating an NVIDIA GPU)
if command -v nvidia-smi &>/dev/null; then
    echo "NVIDIA GPU detected."
    
    # Check if the NVIDIA runtime is available in Docker
    if docker info | grep -q "Runtimes:.*nvidia"; then
        echo "Docker NVIDIA runtime is available."
        DOCKER_OPTS+=("--gpus" "all")
    else
        echo "Docker NVIDIA runtime is NOT available."
    fi
else
    echo "No NVIDIA GPU detected."
fi

DOCKER_OPTS+=("-v" "`pwd`/../Commands/bin:/home/kasm-user/bin")
DOCKER_OPTS+=("-v" "`pwd`/../ExampleCode:/home/kasm-user/ExampleCode")
DOCKER_OPTS+=("-v" "`pwd`/../Data:/home/kasm-user/Data")

DOCKER_OPTS+=("--privileged")
DOCKER_OPTS+=("--shm-size=512m")
DOCKER_OPTS+=("-p" "6901:6901")
DOCKER_OPTS+=("-e" "VNC_PW=password")
DOCKER_OPTS+=("pxl_ros2_jazzy:latest")

# Print resulting command (for debugging)
echo "Docker command: docker run ${DOCKER_OPTS[*]}"

## Run the Docker command
docker run "${DOCKER_OPTS[@]}"
