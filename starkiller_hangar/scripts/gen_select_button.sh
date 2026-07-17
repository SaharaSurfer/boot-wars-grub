#!/bin/bash

set -euo pipefail

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd) 
FONT="${PROJECT_DIR}/assets/medium_font.ttf"
FONT_SIZE=24

TEXT_STRING="f_ .q- j| _y. ^k -g/ .p_ {z}"
TEXT_POS_X=10
TEXT_POS_Y=0

W=238
H=52
CUT=4

COLOR_BG="rgba(0, 0, 0, 0.6)"
COLOR_BORDER="#ffb700"
COLOR_SCANLINE_BRIGHT="#632204"
COLOR_SCANLINE_DARK="#4a1500"

MASK_STROKE=4
MASK_BLUR="0x8"

# ==============================================================================

# At the time of writing, latest version of ImageMagick is 7.1.2-27,
# but the script was originally made with 7.1.2-12. This matters because
# somewhere between these versions something related to the alpha channel /
# composition changed, which alters the final look. I don't really have the
# time or desire to sort this out, so here's dumb plug for an old version 
# built from source 
MAGICK_OLD="/opt/imagemagick-7.1.2-12/bin/magick"

# generate text mask for scanlines
$MAGICK_OLD -background none \
    -fill white \
    -font "$FONT" \
    -pointsize $FONT_SIZE \
    -gravity West \
    label:"$TEXT_STRING" \
    -trim +repage \
    ${WORK_DIR}/mask_text.png

# generate container for selected item
$MAGICK_OLD -size ${W}x${H} xc:none \
    -fill "$COLOR_BG" \
    -stroke "$COLOR_BORDER" \
    -strokewidth 2 \
    -draw "roundrectangle 1,1 $((W-2)),$((H-2)) 4,4" \
    -stroke "none" \
    -fill "$COLOR_BORDER" \
    ${WORK_DIR}/base.png

# obtain final mask (text + container)
$MAGICK_OLD -size ${W}x${H} xc:black \
    -fill none \
    -stroke white \
    -strokewidth $MASK_STROKE \
    -draw "roundrectangle 1,1 $((W-2)),$((H-2)) 4,4" \
    \( \
        ${WORK_DIR}/mask_text.png \
       -alpha extract \
       -threshold 50% \
       -morphology Close "Disk:1" \
       -morphology Dilate "Disk:1" \
    \) \
    -gravity West \
    -geometry +${TEXT_POS_X}+${TEXT_POS_Y} \
    -compose Plus \
    -composite \
    -blur $MASK_BLUR \
    ${WORK_DIR}/mask.png

# apply scanlines with mask as alpha channel
$MAGICK_OLD ${WORK_DIR}/base.png \
    \( \
        -size ${W}x${H} xc:none \
        \( \
            -size 1x3 xc:"$COLOR_SCANLINE_DARK" \
            -fill "$COLOR_SCANLINE_BRIGHT" \
            -draw "point 0,0" \
            -write mpr:scanline +delete \
        \) \
        -fill mpr:scanline \
        -draw "color 0,0 reset" \
        \( \
            ${WORK_DIR}/mask.png \
            -alpha off \
            -alpha copy \
        \) \
        -compose DstIn \
        -composite \
    \) \
    -compose Plus \
    -composite \
    ${WORK_DIR}/select_final.png

# slice button into 9 areas used by grub
slice_fixed_width() {
    INPUT=$1
    PREFIX=$2
    CENTER_W=$((W - CUT * 2))
        
    $MAGICK_OLD $INPUT \
        -crop ${CUT}x${CUT}+0+0 +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_nw.png

    $MAGICK_OLD $INPUT \
        -crop ${CUT}x${CUT}+$((W-CUT))+0 +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_ne.png

    $MAGICK_OLD $INPUT \
        -crop ${CUT}x${CUT}+0+$((H-CUT)) +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_sw.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CUT}x${CUT}+$((W-CUT))+$((H-CUT)) +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_se.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CUT}x$((H - CUT*2))+0+${CUT} +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_w.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CUT}x$((H - CUT*2))+$((W-CUT))+${CUT} +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_e.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CENTER_W}x${CUT}+${CUT}+0 +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_n.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CENTER_W}x${CUT}+${CUT}+$((H-CUT)) +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_s.png
    
    $MAGICK_OLD $INPUT \
        -crop ${CENTER_W}x$((H - CUT*2))+${CUT}+${CUT} +repage \
        png32:${PROJECT_DIR}/theme/${PREFIX}_c.png
}

slice_fixed_width "${WORK_DIR}/select_final.png" "select"

echo "SUCCESS! Select button generated."
