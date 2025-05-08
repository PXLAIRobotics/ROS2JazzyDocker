#!/bin/bash

# GUI Applications with Docker on MacOS WITHOUT VNC is currently not supported.
if [[ "$(uname)" == "Darwin" ]]; then
    echo "GUI Applications with Docker on MacOS WITHOUT VNC is currently not supported."
    read -p "GUI applications will not work. Continue? (y/n): " answer
    if [[ "$answer" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
        echo "Starting Docker container..."
    else
        echo "Aborted."
        exit 1
    fi
fi


# Initialize an empty list (array)
DOCKER_OPTS=()
DOCKER_OPTS+=("--privileged" "-it" "--rm") 
DOCKER_OPTS+=("--name=pxl_jazzy")
DOCKER_OPTS+=("--hostname=pxl_jazzy_novnc")

DOCKER_OPTS+=("--volume=/tmp/.X11-unix:/tmp/.X11-unix")
DOCKER_OPTS+=("-v" "`pwd`/../Commands/bin:/home/user/bin")
DOCKER_OPTS+=("-v" "`pwd`/../ExampleCode:/home/user/ExampleCode")
DOCKER_OPTS+=("-v" "`pwd`/../Data:/home/user/Data")
DOCKER_OPTS+=("-v" "`pwd`/../Projects:/home/user/Projects")

DOCKER_OPTS+=("--device=/dev/dri:/dev/dri")
DOCKER_OPTS+=("--env" "DISPLAY=$DISPLAY")
DOCKER_OPTS+=("-e" "TERM=xterm-256color")
DOCKER_OPTS+=("--cap-add" "SYS_ADMIN")
DOCKER_OPTS+=("--device" "/dev/fuse")


# Detect CPU Architecture
ARCH=$(uname -m)
# Check if running on ARM (Apple Silicon or other ARM-based CPUs)
# Reason: Some ROS2 packages only run on AMD64 architectures.
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    DOCKER_OPTS+=("--platform=linux/amd64") # Force Docker to run AMD64
fi

# Check if nvidia-smi is available (indicating an NVIDIA GPU)
if command -v nvidia-smi &>/dev/null; then
    echo "NVIDIA GPU detected."

    # Run nvidia-smi and capture its exit code
    nvidia-smi &>/dev/null
    EXIT_CODE=$?
    echo $EXIT_CODE

    if [[ $EXIT_CODE -eq 0 || $EXIT_CODE -eq 139 ]]; then
        echo "nvidia-smi executed successfully (Exit code: $EXIT_CODE)."

        # Check if the NVIDIA runtime is available in Docker
        if docker info | grep -q "Runtimes:.*nvidia"; then
            echo "Docker NVIDIA runtime is available."
            # DOCKER_OPTS+=("--gpus" "all") # TODO: Enable NVidia GPU support
        else
            echo "Docker NVIDIA runtime is NOT available."
        fi
    else
        echo "nvidia-smi failed (Exit code: $EXIT_CODE). Skipping GPU options."
    fi
else
    echo "No NVIDIA GPU detected."
fi

DOCKER_OPTS+=("--shm-size=1GB")
DOCKER_OPTS+=("pxl_ros2_jazzy_novnc:latest")
DOCKER_OPTS+=("bash")

# Print resulting command (for debugging)
echo "Docker command: docker run ${DOCKER_OPTS[*]}"

# Run the Docker command
docker run "${DOCKER_OPTS[@]}"
