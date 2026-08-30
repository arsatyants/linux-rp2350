#!/bin/bash
# Build a user app and run it on RP2350-MINI-A over the serial console.
# Usage: ./scripts/debug.sh [APP]
# APP is the basename of an apps/*.c file (default: hello).
set -e

APP="${1:-hello}"
APPS_DIR="${APPS_DIR:-$(readlink -f "$(dirname "$0")/../apps")}"
PORT="${PORT:-/dev/ttyUSB0}"
BAUD="${BAUD:-115200}"

if [ ! -f "$APPS_DIR/$APP.c" ]; then
    echo "Error: $APPS_DIR/$APP.c not found" >&2
    exit 1
fi

cd "$APPS_DIR"
make clean
make "$APP"

python3 send.py "$APP" --port "$PORT" --baud "$BAUD"
