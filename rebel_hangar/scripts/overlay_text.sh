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

LOGO_IMAGE="${PROJECT_DIR}/assets/logo.png"
LOGO_X=110
LOGO_Y=979

LABEL_COLOR="#ffb700"
LABEL_FONT="${PROJECT_DIR}/assets/overlay_font.ttf"
LABEL_SIZE=16
LABEL_PRIMARY_LEFT="REBEL ALLIANCE FLEET"
LABEL_PRIMARY_RIGHT="AWAITING DEPLOYMENT"
LABEL_SECONDARY="FLIGHTS COMPLETED: 378"
LABEL_INTERLINE_SPACER=14
LABEL_OFFSET_X=29
LABEL_OFFSET_Y=7

DOT_IMAGE="${PROJECT_DIR}/assets/dot.png"
DOT_SPACER=8

# 1 bright + 2 dark
SCANLINE_BRIGHT_COLOR="#632204"
SCANLINE_DARK_COLOR="#4a1500"
SCANLINE_SPACER=45  # needed so scanlines fade out smoothly

OVERLAY_X=$(( LOGO_X - SCANLINE_SPACER ))
OVERLAY_Y=$(( LOGO_Y - SCANLINE_SPACER ))

# a bunch of temp paths since they're used a lot
IMAGE_LABEL_PRIMARY_LEFT="${WORK_DIR}/label_primary_left.png"
IMAGE_LABEL_PRIMARY_RIGHT="${WORK_DIR}/label_primary_right.png"
IMAGE_LABEL_PRIMARY="${WORK_DIR}/label_primary.png"
IMAGE_LABEL_SECONDARY="${WORK_DIR}/label_secondary.png"
IMAGE_LABELS_STACK="${WORK_DIR}/labels_stack.png"
IMAGE_INNER_CONTENT="${WORK_DIR}/inner_content.png"
IMAGE_TIP_BOX="${WORK_DIR}/tip_box.png"
IMAGE_TIP_MASK="${WORK_DIR}/tip_mask.png"

# ==============================================================================

# generate 1st line, 1st part
magick -background none \
    -fill "$LABEL_COLOR" \
    -font "$LABEL_FONT" \
    -pointsize $LABEL_SIZE \
    label:"$LABEL_PRIMARY_LEFT" \
    "$IMAGE_LABEL_PRIMARY_LEFT"

# generate 1st line, 2nd part
magick -background none \
    -fill "$LABEL_COLOR" \
    -font "$LABEL_FONT" \
    -pointsize $LABEL_SIZE \
    label:"$LABEL_PRIMARY_RIGHT" \
    "$IMAGE_LABEL_PRIMARY_RIGHT"

# join 1st and 2nd part with dot delimeter
magick -background none \
    "$IMAGE_LABEL_PRIMARY_LEFT" \
    \( \
        "$DOT_IMAGE" \
        -gravity South \
        -background none \
        -splice 0x4 \
    \) \
    "$IMAGE_LABEL_PRIMARY_RIGHT" \
    -gravity center \
    +smush $DOT_SPACER \
    "$IMAGE_LABEL_PRIMARY"

# generate 2nd line
magick -background none \
    -fill "$LABEL_COLOR" \
    -font "$LABEL_FONT" \
    -pointsize $LABEL_SIZE \
    label:"$LABEL_SECONDARY" \
    "$IMAGE_LABEL_SECONDARY"

# stack 1st and 2nd line
magick -background none \
    "$IMAGE_LABEL_PRIMARY" \
    "$IMAGE_LABEL_SECONDARY" \
    -gravity West \
    -smush $LABEL_INTERLINE_SPACER \
    "$IMAGE_LABELS_STACK"

# add logo on the left
magick -background none \
    "$LOGO_IMAGE" \
    \( \
        "$IMAGE_LABELS_STACK" \
        -gravity North \
        -splice 0x${LABEL_OFFSET_Y} \
    \) \
    -gravity center \
    +smush $LABEL_OFFSET_X \
    "$IMAGE_INNER_CONTENT"

# determine size of the current container
CONTENT_W=$(magick identify -format "%w" "$IMAGE_INNER_CONTENT")
CONTENT_H=$(magick identify -format "%h" "$IMAGE_INNER_CONTENT")

# padded canvas for smooth fade out
CANVAS_W=$((SCANLINE_SPACER + CONTENT_W + SCANLINE_SPACER))
CANVAS_H=$((SCANLINE_SPACER + CONTENT_H + SCANLINE_SPACER))

# text position on padded canvas
TXT_POS="+${SCANLINE_SPACER}+${SCANLINE_SPACER}"

# place text on bigger canvas and brighten antialiased pixels
magick -size ${CANVAS_W}x${CANVAS_H} xc:none \
    \( \
        "$IMAGE_INNER_CONTENT" \
        -fill "$LABEL_COLOR" \
        -colorize 100 \
    \) \
    \
    -geometry "$TXT_POS" \
    -composite \
    "$IMAGE_INNER_CONTENT" \
    -geometry "$TXT_POS" \
    -composite \
    "$IMAGE_TIP_BOX"

# generate mask for scanlines
magick -size ${CANVAS_W}x${CANVAS_H} xc:black \
    \( \
        "$IMAGE_INNER_CONTENT"  \
        -alpha extract \
        -threshold 50% \
        -morphology Close "Disk:9" \
        -morphology Dilate "Disk:25" \
    \) \
    -geometry "$TXT_POS" \
    -compose Plus \
    -composite \
    -blur 0x16 \
    -evaluate Multiply 1.2 \
    -alpha off \
    -colorspace gray \
    "$IMAGE_TIP_MASK"

# add scanlines behind text
magick "$IMAGE_TIP_BOX" \
    \( \
        -size ${CANVAS_W}x${CANVAS_H} xc:none \
        \( \
            -size 1x3 xc:"$SCANLINE_DARK_COLOR" \
            -fill "$SCANLINE_BRIGHT_COLOR" \
            -draw "point 0,0" \
            -write mpr:scanline +delete \
        \) \
        -fill mpr:scanline \
        -draw "color 0,0 reset" \
        "$IMAGE_TIP_MASK" \
        -compose CopyOpacity \
        -composite \
        \( \
            "$IMAGE_INNER_CONTENT" \
            -geometry "$TXT_POS" \
        \) \
        -compose DstOut \
        -composite \
    \) \
    -compose Over \
    -composite \
    "$IMAGE_TIP_BOX"

# place final result on top of background image
magick "$INPUT" \
    "$IMAGE_TIP_BOX" \
    -geometry +${OVERLAY_X}+${OVERLAY_Y} \
    -composite \
    "$OUTPUT"

echo "SUCCESS! Text overlaid."
