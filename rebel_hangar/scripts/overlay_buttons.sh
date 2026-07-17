#!/bin/bash

# ImageMagick 7.1.2-27

set -euo pipefail

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
INPUT="${PROJECT_DIR}/assets/wallpaper_burned.png"
OUTPUT="${PROJECT_DIR}/theme/background.png"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            INPUT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

SELECT_IMAGE="${PROJECT_DIR}/assets/select.png"
SELECT_WIDTH=$(magick identify -format "%w" "$SELECT_IMAGE")
SELECT_HEIGHT=$(magick identify -format "%h" "$SELECT_IMAGE")

EDIT_IMAGE="${PROJECT_DIR}/assets/edit.png"
EDIT_WIDTH=$(magick identify -format "%w" "$EDIT_IMAGE")
EDIT_HEIGHT=$(magick identify -format "%h" "$EDIT_IMAGE")

CONSOLE_IMAGE="${PROJECT_DIR}/assets/console.png"
CONSOLE_WIDTH=$(magick identify -format "%w" "$CONSOLE_IMAGE")
CONSOLE_HEIGHT=$(magick identify -format "%h" "$CONSOLE_IMAGE")

PILL_GAP=24

POS_X_SELECT=1377
POS_X_EDIT=$(( POS_X_SELECT + SELECT_WIDTH + PILL_GAP ))
POS_X_CONSOLE=$(( POS_X_EDIT + EDIT_WIDTH + PILL_GAP ))

POS_Y=1021

# ==============================================================================

# insert select pill
magick "$INPUT" \
    "$SELECT_IMAGE" \
    -geometry +${POS_X_SELECT}+${POS_Y} \
    -composite \
    "${WORK_DIR}/step1.png"

# insert edit pill
magick "${WORK_DIR}/step1.png" \
    "$EDIT_IMAGE" \
    -geometry +${POS_X_EDIT}+${POS_Y} \
    -composite \
    "${WORK_DIR}/step2.png"

# insert console pill
magick "${WORK_DIR}/step2.png" \
    "$CONSOLE_IMAGE" \
    -geometry +${POS_X_CONSOLE}+${POS_Y} \
    -composite \
    "$OUTPUT"

echo "SUCCESS! Buttons overlaid."
