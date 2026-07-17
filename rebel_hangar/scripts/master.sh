#!/bin/bash

# ImageMagick 7.1.2-27

set -euo pipefail

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUTTON_SCRIPT="${SCRIPT_DIR}/generate_button.sh"
OVERLAY_BUTTONS_SCRIPT="${SCRIPT_DIR}/overlay_buttons.sh"
OVERLAY_TEXT_SCRIPT="${SCRIPT_DIR}/overlay_text.sh"

for s in "$BUTTON_SCRIPT" "$OVERLAY_BUTTONS_SCRIPT" "$OVERLAY_TEXT_SCRIPT"; do
    if [[ ! -f "$s" ]]; then
        echo "Missing script: $s" >&2
        exit 1
    fi
done

PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
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

if [[ ! -f "$INPUT" ]]; then
    echo "Input not found: $INPUT" >&2
    exit 1
fi

# generate buttons
"$BUTTON_SCRIPT" -k "ENTER" -h "SELECT" -o "${WORK_DIR}/select.png"
magick "${WORK_DIR}/select.png" \
    -filter Catrom \
    -resize x45 \
    "${PROJECT_DIR}/assets/select.png"

"$BUTTON_SCRIPT" -k "E" -h "EDIT" -o "${WORK_DIR}/edit.png"
magick "${WORK_DIR}/edit.png" \
    -filter Catrom \
    -resize x45 \
    "${PROJECT_DIR}/assets/edit.png"

"$BUTTON_SCRIPT" -k "C" -h "CONSOLE" -o "${WORK_DIR}/console.png"
magick "${WORK_DIR}/console.png" \
    -filter Catrom \
    -resize x45 \
    "${PROJECT_DIR}/assets/console.png"

# overlay_buttons
"$OVERLAY_BUTTONS_SCRIPT" -i "${INPUT}" -o "${WORK_DIR}/bg_with_overlay.png"

# overlay text
"$OVERLAY_TEXT_SCRIPT" -i "${WORK_DIR}/bg_with_overlay.png" -o "$OUTPUT"

echo "SUCCESS! Theme background assembled."
