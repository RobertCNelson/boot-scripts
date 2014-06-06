#!/bin/sh

export XDG_RUNTIME_DIR="/tmp/wayland"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"

echo "drm:"
echo "weston --backend=drm-backend.so --use-pixman"

echo "fbdev:"
echo "weston --backend=fbdev-backend.so"

