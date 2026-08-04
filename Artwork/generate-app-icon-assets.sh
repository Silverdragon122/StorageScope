#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
SOURCE_SVG="$SCRIPT_DIR/AppIcon.svg"
SMALL_SOURCE_SVG="$SCRIPT_DIR/AppIcon-small.svg"
ASSET_DIR="$SCRIPT_DIR/../StorageScope/Assets.xcassets/AppIcon.appiconset"

if ! command -v rsvg-convert >/dev/null 2>&1; then
    print -u2 "rsvg-convert is required to render AppIcon.svg"
    exit 1
fi

typeset -A outputs=(
    AppIcon-16.png 16
    AppIcon-16@2x.png 32
    AppIcon-32.png 32
    AppIcon-32@2x.png 64
    AppIcon-128.png 128
    AppIcon-128@2x.png 256
    AppIcon-256.png 256
    AppIcon-256@2x.png 512
    AppIcon-512.png 512
    AppIcon-512@2x.png 1024
)

for filename pixels in ${(kv)outputs}; do
    source="$SOURCE_SVG"
    if (( pixels <= 64 )); then
        source="$SMALL_SOURCE_SVG"
    fi

    rsvg-convert \
        --width "$pixels" \
        --height "$pixels" \
        --keep-aspect-ratio \
        --output "$ASSET_DIR/$filename" \
        "$source"
done
