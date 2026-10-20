#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
exec "$SCRIPT_DIR/pxl_ros2_jazzy_novnc_image/02_run_container.sh"
