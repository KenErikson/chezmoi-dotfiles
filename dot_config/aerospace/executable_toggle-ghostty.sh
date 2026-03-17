#!/bin/bash

STATE_FILE="/tmp/ghostty_dropdown_id"
touch "$STATE_FILE"
WIN_ID=$(cat "$STATE_FILE")

# 1. Verify if the saved window ID still exists
VALID_WIN=""
if [ -n "$WIN_ID" ]; then
  VALID_WIN=$(aerospace list-windows --all --format "%{window-id} | %{app-name}" | awk -v id="$WIN_ID" '$1 == id && $3 == "Ghostty" {print $1}')
fi

# 2. Get the workspace currently visible on the monitor where the mouse is
MOUSE_WS=$(aerospace list-workspaces --monitor mouse --visible)

if [ -z "$VALID_WIN" ]; then
  # Window doesn't exist. Spawn it in the home directory and tell the process to DIE if closed.
  /Applications/Ghostty.app/Contents/MacOS/ghostty --title="GhosttyDropdown" --working-directory="$HOME" --quit-after-last-window-closed=true &

  sleep 0.4

  NEW_ID=$(aerospace list-windows --all --format "%{window-id} | %{window-title}" | grep "GhosttyDropdown" | awk '{print $1}' | head -n 1)

  if [ -n "$NEW_ID" ]; then
    echo "$NEW_ID" >"$STATE_FILE"
    # Force it immediately to the mouse monitor and focus
    aerospace move-node-to-workspace --window-id "$NEW_ID" "$MOUSE_WS"
    aerospace focus --window-id "$NEW_ID"
  fi
else
  # Window exists! Check focus status
  FOCUSED_ID=$(aerospace list-windows --focused --format "%{window-id}")

  if [ "$WIN_ID" == "$FOCUSED_ID" ]; then
    # It is focused right now -> Banish it to background workspace 'S'
    aerospace move-node-to-workspace --window-id "$WIN_ID" S
  else
    # It is hidden OR on another monitor -> Summon it to the mouse monitor
    aerospace move-node-to-workspace --window-id "$WIN_ID" "$MOUSE_WS"
    aerospace focus --window-id "$WIN_ID"
  fi
fi
