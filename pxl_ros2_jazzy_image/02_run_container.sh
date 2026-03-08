#!/bin/bash

# Performance-focused run script (workshop-perf-default branch).
# - Lower default VNC resolution + FPS, disable optional Kasm services
# - NVIDIA GPU: --gpus all + OpenGL env vars
# - Intel/AMD: /dev/dri + HW3D when no NVIDIA
# - --ipc=host, --shm-size=2GB

ARCH=$(uname -m)

DOCKER_OPTS=()
DOCKER_OPTS+=("--name=pxl_jazzy")
DOCKER_OPTS+=("--hostname=pxl_jazzy")
DOCKER_OPTS+=("--rm" "-it")

# Check if running on ARM (Apple Silicon or ARM-based Linux)
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    DOCKER_OPTS+=("--platform=linux/amd64")
fi

# GPU: NVIDIA
if command -v nvidia-smi &>/dev/null; then
    echo "NVIDIA GPU detected."
    nvidia-smi &>/dev/null
    EXIT_CODE=$?
    echo $EXIT_CODE

    if [[ $EXIT_CODE -eq 0 || $EXIT_CODE -eq 139 ]]; then
        echo "nvidia-smi executed successfully (Exit code: $EXIT_CODE)."
        if docker info | grep -q "Runtimes:.*nvidia"; then
            echo "Docker NVIDIA runtime is available."
            DOCKER_OPTS+=("--gpus" "all")
            DOCKER_OPTS+=("-e" "__GLX_VENDOR_LIBRARY_NAME=nvidia")
            DOCKER_OPTS+=("-e" "__NV_PRIME_RENDER_OFFLOAD=1")
        else
            echo "Docker NVIDIA runtime is NOT available."
        fi
    else
        echo "nvidia-smi failed (Exit code: $EXIT_CODE). Skipping GPU options."
    fi
else
    echo "No NVIDIA GPU detected."
fi

# GPU: Intel/AMD via /dev/dri (when NVIDIA not in use)
if [[ -d /dev/dri ]] && ! echo "${DOCKER_OPTS[*]}" | grep -q "\-\-gpus"; then
    echo "/dev/dri found on host, enabling DRI devices and HW3D."
    DOCKER_OPTS+=("--device=/dev/dri")
    RENDER_GID=$(getent group render 2>/dev/null | cut -d: -f3)
    VIDEO_GID=$(getent group video 2>/dev/null | cut -d: -f3)
    [[ -n "$RENDER_GID" ]] && DOCKER_OPTS+=("--group-add=$RENDER_GID")
    [[ -n "$VIDEO_GID" ]]  && DOCKER_OPTS+=("--group-add=$VIDEO_GID")
    DOCKER_OPTS+=("-e" "HW3D=true")
fi

# Volumes
DOCKER_OPTS+=("-v" "`pwd`/../Commands/bin:/home/kasm-user/bin")
DOCKER_OPTS+=("-v" "`pwd`/../ExampleCode:/home/kasm-user/ExampleCode")
DOCKER_OPTS+=("-v" "`pwd`/../Data:/home/kasm-user/Data")
DOCKER_OPTS+=("-v" "`pwd`/../Projects:/home/kasm-user/Projects")

# Runtime tuning
DOCKER_OPTS+=("--privileged")
DOCKER_OPTS+=("--ipc=host")
DOCKER_OPTS+=("--shm-size=2GB")

# VNC / Kasm tuning
DOCKER_OPTS+=("-e" "VNC_RESOLUTION=${VNC_RESOLUTION:-1280x720}")
DOCKER_OPTS+=("-e" "MAX_FRAME_RATE=${MAX_FRAME_RATE:-20}")
DOCKER_OPTS+=("-e" "VNC_COL_DEPTH=${VNC_COL_DEPTH:-24}")
DOCKER_OPTS+=("-e" "KASM_SVC_AUDIO=${KASM_SVC_AUDIO:-0}")
DOCKER_OPTS+=("-e" "KASM_SVC_AUDIO_INPUT=${KASM_SVC_AUDIO_INPUT:-0}")
DOCKER_OPTS+=("-e" "KASM_SVC_WEBCAM=${KASM_SVC_WEBCAM:-0}")
DOCKER_OPTS+=("-e" "KASM_SVC_GAMEPAD=${KASM_SVC_GAMEPAD:-0}")
DOCKER_OPTS+=("-e" "KASM_SVC_UPLOADS=${KASM_SVC_UPLOADS:-0}")
DOCKER_OPTS+=("-e" "KASM_SVC_PRINTER=${KASM_SVC_PRINTER:-0}")

# Networking / auth
DOCKER_OPTS+=("-p" "6901:6901")
DOCKER_OPTS+=("-e" "VNC_PW=password")

DOCKER_OPTS+=("pxl_ros2_jazzy:latest")

echo "Docker command: docker run ${DOCKER_OPTS[*]}"
docker run "${DOCKER_OPTS[@]}"
