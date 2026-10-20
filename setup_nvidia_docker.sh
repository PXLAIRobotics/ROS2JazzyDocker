#!/bin/bash
set -euo pipefail

# One-time host setup using NVIDIA's stable apt repository:
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
if [[ $EUID -ne 0 ]]; then
    echo "Run this host setup with sudo: sudo bash $0" >&2
    exit 1
fi
if ! command -v apt-get >/dev/null || ! command -v systemctl >/dev/null; then
    echo "This setup requires an apt-based Linux host with systemd." >&2
    exit 1
fi
if ! nvidia-smi; then
    echo "The host NVIDIA driver must work before installing the container toolkit." >&2
    exit 1
fi
if ! command -v docker >/dev/null; then
    echo "Install Docker Engine before running this setup." >&2
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg
SETUP_DIR=$(mktemp -d)
cleanup() {
    rm -f -- "$SETUP_DIR/gpgkey" "$SETUP_DIR/keyring.gpg" "$SETUP_DIR/toolkit.list" "$SETUP_DIR/repository.list"
    rmdir -- "$SETUP_DIR"
}
trap cleanup EXIT
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey -o "$SETUP_DIR/gpgkey"
gpg --batch --dearmor -o "$SETUP_DIR/keyring.gpg" "$SETUP_DIR/gpgkey"
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list -o "$SETUP_DIR/toolkit.list"
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    "$SETUP_DIR/toolkit.list" > "$SETUP_DIR/repository.list"
install -m 644 "$SETUP_DIR/keyring.gpg" /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
install -m 644 "$SETUP_DIR/repository.list" /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit

# nvidia-ctk preserves other Docker daemon settings. Keep a backup as well.
if [[ -f /etc/docker/daemon.json ]]; then
    cp -p /etc/docker/daemon.json "/etc/docker/daemon.json.before-nvidia.$(date +%Y%m%d%H%M%S)"
fi
nvidia-ctk runtime configure --runtime=docker
echo "Restarting Docker to load the NVIDIA runtime (running containers may stop)."
systemctl restart docker
echo "NVIDIA runtime configured. Verify with:"
echo "docker run --rm --runtime=nvidia --gpus all pxl_ros2_jazzy_novnc:latest nvidia-smi"
echo "Then run ./002b_run_pxl_ros2_jazzy_novnc_container.sh and check glxinfo -B."
