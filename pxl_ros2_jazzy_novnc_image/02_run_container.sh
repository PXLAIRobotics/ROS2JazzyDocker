#!/bin/bash
set -euo pipefail

# This image uses the host's X11/Xwayland display (no VNC server).
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This launcher requires a local Linux X11/Xwayland display. Use ./002_run_pxl_ros2_jazzy_container.sh for KasmVNC." >&2
    exit 1
fi
if [[ -z "${DISPLAY:-}" ]]; then
    echo "DISPLAY is unset. Run this script from a terminal in your graphical desktop session." >&2
    exit 1
fi
case "$DISPLAY" in
    :*|unix:*) ;;
    *) echo "DISPLAY=$DISPLAY is not a local X11 display; SSH/TCP displays are not supported by this launcher." >&2; exit 1 ;;
esac
DISPLAY_NUMBER=${DISPLAY##*:}
DISPLAY_NUMBER=${DISPLAY_NUMBER%%.*}
if [[ ! -S "/tmp/.X11-unix/X$DISPLAY_NUMBER" ]]; then
    echo "No X11 socket found for DISPLAY=$DISPLAY. Check your desktop session's DISPLAY." >&2
    exit 1
fi
if ! command -v xauth >/dev/null 2>&1; then
    echo "Install xauth on the host (sudo apt install xauth) and run this script again." >&2
    exit 1
fi
if ! DOCKER_RUNTIMES=$(docker info --format '{{range $name, $runtime := .Runtimes}}{{$name}} {{end}}'); then
    echo "Cannot access Docker. Check that the daemon is running and your user has permission to use it." >&2
    exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

# Keep the cookie in a private host directory. The file must be readable by the
# image's user, whose UID may differ. FamilyWild matches the container hostname.
XAUTH_DIR=$(mktemp -d /tmp/pxl-jazzy-xauth.XXXXXX)
cleanup() {
    rm -f -- "$XAUTH_DIR/Xauthority"
    rmdir -- "$XAUTH_DIR"
}
trap cleanup EXIT
touch "$XAUTH_DIR/Xauthority"
XAUTH_ENTRIES=$(xauth -i nlist "$DISPLAY")
if [[ -z "$XAUTH_ENTRIES" ]]; then
    echo "No Xauthority cookie found for DISPLAY=$DISPLAY. Run from your desktop terminal and check XAUTHORITY." >&2
    exit 1
fi
printf '%s\n' "$XAUTH_ENTRIES" | sed 's/^..../ffff/' | xauth -f "$XAUTH_DIR/Xauthority" nmerge -
chmod 644 "$XAUTH_DIR/Xauthority"

DOCKER_OPTS=("--privileged" "-it" "--rm" "--name=pxl_jazzy" "--hostname=pxl_jazzy_novnc")
DOCKER_OPTS+=("--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro")
# Xwayland may create a group-writable socket rather than a world-writable one.
DOCKER_OPTS+=("--group-add=$(stat -c %g "/tmp/.X11-unix/X$DISPLAY_NUMBER")")
DOCKER_OPTS+=("--volume=$XAUTH_DIR/Xauthority:/tmp/pxl.Xauthority:ro")
DOCKER_OPTS+=("--env" "DISPLAY=$DISPLAY" "--env" "XAUTHORITY=/tmp/pxl.Xauthority")
for directory in Commands/bin ExampleCode Data Projects; do
    DOCKER_OPTS+=("-v" "$REPO_DIR/$directory:/home/user/${directory##*/}")
done
DOCKER_OPTS+=("-e" "TERM=xterm-256color" "-e" "QT_X11_NO_MITSHM=1")
DOCKER_OPTS+=("--cap-add" "SYS_ADMIN")
if [[ -e /dev/fuse ]]; then
    DOCKER_OPTS+=("--device" "/dev/fuse")
fi

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    DOCKER_OPTS+=("--platform=linux/amd64")
fi

if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    if [[ " $DOCKER_RUNTIMES " == *" nvidia "* ]]; then
        echo "NVIDIA GPU and Docker runtime detected; enabling GPU acceleration."
        DOCKER_OPTS+=("--runtime=nvidia" "--gpus" "all")
        DOCKER_OPTS+=("-e" "NVIDIA_DRIVER_CAPABILITIES=graphics,display,utility,compute")
        DOCKER_OPTS+=("-e" "__GLX_VENDOR_LIBRARY_NAME=nvidia" "-e" "__NV_PRIME_RENDER_OFFLOAD=1")
    else
        echo "Docker NVIDIA runtime is unavailable; using Mesa software rendering."
        DOCKER_OPTS+=("-e" "LIBGL_ALWAYS_SOFTWARE=1" "-e" "__GLX_VENDOR_LIBRARY_NAME=mesa")
    fi
elif [[ -d /dev/dri ]]; then
    DOCKER_OPTS+=("--device=/dev/dri:/dev/dri")
    # Use the device's numeric GID; host and image group names may differ.
    for device in /dev/dri/*; do
        [[ -c "$device" ]] && DOCKER_OPTS+=("--group-add=$(stat -c %g "$device")")
    done
fi

DOCKER_OPTS+=("--shm-size=1GB" "pxl_ros2_jazzy_novnc:latest" "bash")
printf 'Docker command: docker run'
printf ' %q' "${DOCKER_OPTS[@]}"
printf '\n'
docker run "${DOCKER_OPTS[@]}"
