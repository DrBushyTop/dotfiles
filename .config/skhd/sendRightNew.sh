#!/bin/bash

# Get the ID of the currently focused window
focused_window=$(yabai -m query --windows --window | jq -r '.id')

# Check if we have a focused window
if [ -z "$focused_window" ]; then
	echo "No focused window found."
	exit 1
fi

# Move the focused window to the screen to the left
yabai -m window "$focused_window" --display next

# Optional: focus the window after moving it
yabai -m window --focus "$focused_window"
