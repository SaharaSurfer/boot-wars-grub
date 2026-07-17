#!/bin/bash

# ImageMagick 7.1.2-27 works fine

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd) 
INPUT_IMAGE="${PROJECT_DIR}/assets/wallpaper.png"
OUTPUT_IMAGE="${PROJECT_DIR}/assets/wallpaper_blured.png"

magick "$INPUT_IMAGE" \
    -blur "0x6" \
    -attenuate 0.03 \
    +noise Gaussian \
    "$OUTPUT_IMAGE"
    