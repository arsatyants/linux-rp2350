#!/bin/bash
# Build a user app, embed it into the rootfs, rebuild the full image and flash.
# Usage: ./scripts/release.sh [APP]
# APP is the basename of an apps/*.c file (default: hello).
set -e

BUILD_ONLY=false

while [ $# -gt 0 ]; do
    case "$1" in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

APP="${1:-hello}"
PROJECT_DIR="$(readlink -f "$(dirname "$0")/..")"
APPS_DIR="$PROJECT_DIR/apps"
BOARD_DIR="$PROJECT_DIR/board/raspberrypi/raspberrypi-pico2"
OVERLAY_DIR="$BOARD_DIR/rootfs_overlay"
BUILDROOT_DIR="$PROJECT_DIR/buildroot"
IMAGE="$BUILDROOT_DIR/output/images/flash-image.uf2"
PICOTOOL="${PICOTOOL:-$HOME/.local/bin/picotool}"

if [ ! -f "$APPS_DIR/$APP.c" ]; then
    echo "Error: $APPS_DIR/$APP.c not found" >&2
    exit 1
fi

make -C "$APPS_DIR" clean
make -C "$APPS_DIR" "$APP"

# Install into the overlay so it survives in the read-only cramfs.
mkdir -p "$OVERLAY_DIR/usr/bin"
cp -v "$APPS_DIR/$APP" "$OVERLAY_DIR/usr/bin/$APP"

cd "$PROJECT_DIR"
make -C "$BUILDROOT_DIR" -j"$(nproc)"

if [ "$BUILD_ONLY" = true ]; then
    echo ""
    echo "Build-only mode: image ready at $IMAGE"
    echo "Run without --build-only to flash after putting the board into BOOTSEL."
    exit 0
fi

echo ""
echo "======================================"
echo "Image built: $IMAGE"
echo "Put the RP2350-MINI-A into BOOTSEL and press ENTER to flash"
echo "======================================"
read -r

sudo "$PICOTOOL" load -fu "$IMAGE"

echo ""
echo "Flash complete. Reboot into application? (y/n)"
read -r ans
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
    sudo "$PICOTOOL" reboot
fi
