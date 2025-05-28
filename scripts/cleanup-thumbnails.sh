#!/bin/bash

CACHE_DIR="$HOME/.cache/thumbnails"
MAX_SIZE=1073741824  # 1GB in bytes

# Get current cache size
current_size=$(du -sb "$CACHE_DIR" | cut -f1)

if (( current_size > MAX_SIZE )); then
    echo "Thumbnails cache exceeds 1GB. Deleting all..."
    rm -rf "${CACHE_DIR:?}/"*
fi
