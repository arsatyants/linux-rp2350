#!/bin/sh
# genimage resolves relative "image" paths against BINARIES_DIR, so make
# sure the static empty-jffs2.bin placeholder is there (genimage.cfg used
# to hardcode an absolute path from a previous build machine, which broke
# on any other checkout location - fixed to a relative path, copied here).
BOARD_DIR="$(dirname "$0")"
cp "${BOARD_DIR}/empty-jffs2.bin" "${BINARIES_DIR}/empty-jffs2.bin"

shift
support/scripts/genimage.sh "$@"

if picotool version > /dev/null; then
	picotool uf2 convert "${BINARIES_DIR}/flash-image.bin" \
		"${BINARIES_DIR}/flash-image.uf2" --family rp2350-riscv
else
	echo "picotool not found, skipping uf2 conversion"
	echo "Please run \`picotool uf2 convert ${BINARIES_DIR}/flash-image.bin \
		${BINARIES_DIR}/flash-image.uf2 --family rp2350-riscv\` insead."
fi
# tput has no controlling terminal in a headless build (e.g. `docker
# build`) and exits nonzero there; since it's the last command in the
# script, that would otherwise make the whole post-image step - and thus
# `make` itself - report failure despite genimage/uf2 conversion having
# already succeeded above. Guard both calls so this is purely cosmetic.
tput smso 2>/dev/null || true
echo "Run \`picotool load -fu ${BINARIES_DIR}/flash-image.uf2\` to flash to pi pico2."
tput rmso 2>/dev/null || true
