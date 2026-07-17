#!/bin/bash

# ImageMagick 7.1.2-27

set -euo pipefail

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

KEY_TEXT="C"
HINT_TEXT="CONSOLE"

ASSETS_DIR=$(cd "$(dirname "$0")/../assets" && pwd) 
FONT="${ASSETS_DIR}/button_font.ttf"
OUTPUT="${ASSETS_DIR}/${HINT_TEXT,,}.png"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -k|--key)
            KEY_TEXT="$2"
            shift 2
            ;;
        -h|--hint)
            HINT_TEXT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

KEY_COLOR="#1a1918"
KEY_SIZE=25
KEY_WIDTH=$(magick -background none \
    -font "$FONT" \
    -pointsize $KEY_SIZE \
    label:"$KEY_TEXT" \
    -format "%w" \
    info:)
KEY_HEIGHT=$(magick -background none \
    -font "$FONT" \
    -pointsize $KEY_SIZE \
    label:"$KEY_TEXT" \
    -format "%h" \
    info:)

KEY_BLOCK_COLOR="#adb9c3"
if [ "${#KEY_TEXT}" -le 1 ]; then
    KEY_TYPE="circle"
    KEY_BLOCK_WIDTH=36
    KEY_BLOCK_HEIGHT=36
    KEY_RADIUS=17.5
else
    KEY_TYPE="pill"
    KEY_BLOCK_WIDTH=$(( 11 + KEY_WIDTH + 11 ))
    KEY_BLOCK_HEIGHT=36
    KEY_RADIUS=$(( KEY_BLOCK_HEIGHT / 2 ))
fi

HINT_COLOR="#adb9c3"
HINT_SIZE=22
HINT_WIDTH=$(magick -background none \
    -font "$FONT" \
    -pointsize $HINT_SIZE \
    label:"$HINT_TEXT" \
    -format "%w" \
    info:)
HINT_HEIGHT=$(magick -background none \
    -font "$FONT" \
    -pointsize $HINT_SIZE \
    label:"$HINT_TEXT" \
    -format "%h" \
    info:)

PILL_BG_COLOR="#1a1918"
PILL_BORDER_COLOR="#333a42"
PILL_PADDING_LEFT=8
PILL_PADDING_RIGHT=23
PILL_SPACER=12
PILL_HEIGHT=54
PILL_WIDTH=$(( 2 + PILL_PADDING_LEFT + KEY_BLOCK_WIDTH + PILL_SPACER \
    + HINT_WIDTH + PILL_PADDING_RIGHT + 2 ))
PILL_RADIUS=$(( PILL_HEIGHT / 2 ))

# relatiive to block
KEY_X=$(( (KEY_BLOCK_WIDTH - KEY_WIDTH) / 2 + 1 ))
KEY_Y=$(( (KEY_BLOCK_HEIGHT - KEY_HEIGHT) / 2 + 3 ))

# relative to pill
KEY_BLOCK_X=$((2 + PILL_PADDING_LEFT))
KEY_BLOCK_Y=$(( (PILL_HEIGHT - KEY_BLOCK_HEIGHT) / 2 ))

# relative to pill
HINT_X=$(( 2 + PILL_PADDING_LEFT + KEY_BLOCK_WIDTH + PILL_SPACER ))
HINT_Y=$(( 3 + (PILL_HEIGHT - HINT_HEIGHT) / 2 ))

# ==============================================================================

# generate pill container
magick -size $((PILL_WIDTH))x$((PILL_HEIGHT)) xc:none \
    -fill "$PILL_BG_COLOR" \
    -stroke "$PILL_BORDER_COLOR" \
    -strokewidth 2 \
    -draw "roundrectangle 0,0 \
        $((PILL_WIDTH-1)),$((PILL_HEIGHT-1)) \
        ${PILL_RADIUS},${PILL_RADIUS}" \
    "${WORK_DIR}/pill.png"

# generate key text
magick -background none \
    -font "$FONT" \
    -pointsize $KEY_SIZE \
    -fill "$KEY_COLOR" \
    label:"$KEY_TEXT" \
    "${WORK_DIR}/key.png"

# generate key block
if [ "$KEY_TYPE" == "circle" ]; then
    magick -size ${KEY_BLOCK_WIDTH}x${KEY_BLOCK_HEIGHT} xc:none \
        -fill "$KEY_BLOCK_COLOR" \
        -draw "circle ${KEY_RADIUS},${KEY_RADIUS} ${KEY_RADIUS},0" \
        "${WORK_DIR}/key_block.png"
else
    magick -size ${KEY_BLOCK_WIDTH}x${KEY_BLOCK_HEIGHT} xc:none \
        -fill "$KEY_BLOCK_COLOR" \
        -draw "roundrectangle 0,0 \
            $((KEY_BLOCK_WIDTH-1)),$((KEY_BLOCK_HEIGHT-1)) \
            ${KEY_RADIUS},${KEY_RADIUS}" \
        "${WORK_DIR}/key_block.png"
fi

# place key text into key block
magick "${WORK_DIR}/key_block.png" \
    "${WORK_DIR}/key.png" \
    -geometry +${KEY_X}+${KEY_Y} \
    -composite \
    "${WORK_DIR}/key_in_block.png"

# generate hint text
magick -background none \
    -font "$FONT" \
    -pointsize $HINT_SIZE \
    -kerning 2 \
    -fill "$HINT_COLOR" \
    label:"$HINT_TEXT" \
    "${WORK_DIR}/hint.png"

# place circle into pill
magick "${WORK_DIR}/pill.png" \
    "${WORK_DIR}/key_in_block.png" \
    -geometry +${KEY_BLOCK_X}+${KEY_BLOCK_Y} \
    -composite \
    "${WORK_DIR}/full_pill.png"

# place hint text into pill
magick "${WORK_DIR}/full_pill.png" \
    "${WORK_DIR}/hint.png" \
    -geometry +${HINT_X}+${HINT_Y} \
    -composite \
    "$OUTPUT"

echo "SUCCESS! Button ${HINT_TEXT} generated."
