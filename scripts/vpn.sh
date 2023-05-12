#!/bin/bash
if ! systemctl is-active --quiet windscribe; then
  sudo systemctl start windscribe
  sleep 7
fi

if ! windscribe status | grep -q "Connected"; then
  windscribe connect && echo "OK";
fi
