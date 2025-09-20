#!/bin/bash

CACHE_DIR="$HOME/.cache/thumbnails"
MAX_SIZE=42949672960  # 40GB in bytes

Get current cache size
current_size=$(du -sb "$CACHE_DIR" | cut -f1)

if (( current_size > MAX_SIZE )); then
    echo "Thumbnails cache exceeds 40GB. Deleting all..."
    rm -rf "${CACHE_DIR:?}/"*
fi

#todo щоб попереджало, коли вже майже в ліміт вперлося + не видаляло, а запитувало чи видаляти.
