#!/bin/bash

# ImageMagick 7.1.2-27 works fine

set -euo pipefail

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
INPUT="${PROJECT_DIR}/assets/wallpaper_blured.png"
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

BUTTON_HEIGHT=56
BUTTON_COUNT=5

# subtract 2px for every item overlap so that borders merge correctly
MENU_HEIGHT=$((BUTTON_HEIGHT * BUTTON_COUNT - (BUTTON_COUNT - 1) * 2))
MENU_WIDTH=246
MENU_X=38
MENU_Y=64

STRIP_HEIGHT=5
CORNER_RADIUS=2

COLOR_BG="rgba(0, 0, 0, 0.75)"
COLOR_BORDER="#788389"
COLOR_STRIP="#313a3f"

# ==============================================================================

STRIPS_CMD=""
DIVIDERS_CMD=""

for (( i=0; i<BUTTON_COUNT; i++ )); do
    # calculate vertical offset for the current button (accounting for overlap)
    OFFSET_Y=$((i * (BUTTON_HEIGHT - 2)))

    # calculate strip Y coordinates relative to the button
    Y2=$((OFFSET_Y + BUTTON_HEIGHT - 3))
    Y1=$((Y2 - (STRIP_HEIGHT - 1)))
    
    # draw the decorative strip inside the button area
    # (2px padding left/right to avoid overlapping the outer border)
    STRIPS_CMD+=" rectangle 2,$Y1 $((MENU_WIDTH-3)),$Y2"

    # add a divider line if this is NOT the last button
    if (( i < BUTTON_COUNT - 1 )); then
        # calculate coordinate for the divider line
        DIV_Y2=$(( i * (BUTTON_HEIGHT - 2) + BUTTON_HEIGHT - 1 ))
        DIV_Y1=$(( DIV_Y2 - 1 ))
        
        # draw a 2px high divider rectangle
        DIVIDERS_CMD+=" rectangle 2,$DIV_Y1 $((MENU_WIDTH-3)),$DIV_Y2"
    fi
done

# generate menu grid
magick -size ${MENU_WIDTH}x${MENU_HEIGHT} xc:none \
    -fill "$COLOR_BORDER" -stroke none \
    -draw "roundrectangle 0,0 \
        $((MENU_WIDTH-1)),$((MENU_HEIGHT-1)) \
        $CORNER_RADIUS,$CORNER_RADIUS" \
    \( \
        +clone -alpha transparent \
        -fill white -stroke none \
        -draw "roundrectangle 2,2 \
            $((MENU_WIDTH-3)),$((MENU_HEIGHT-3)) \
            $CORNER_RADIUS,$CORNER_RADIUS" \
    \) \
    -compose DstOut \
    -composite \
    -compose Over \
    -fill "$COLOR_BG" \
    -draw "roundrectangle 2,2 \
        $((MENU_WIDTH-3)),$((MENU_HEIGHT-3)) \
        $CORNER_RADIUS,$CORNER_RADIUS" \
    -fill "$COLOR_STRIP" \
    -draw "$STRIPS_CMD" \
    -fill "$COLOR_BORDER" \
    -draw "$DIVIDERS_CMD" \
    ${WORK_DIR}/menu.png

# place it on top of wallpaper
magick "$INPUT" \
    ${WORK_DIR}/menu.png \
    -geometry +${MENU_X}+${MENU_Y} \
    -composite \
    "$OUTPUT"

echo "SUCCESS! Grid for menuentries overlaid."
