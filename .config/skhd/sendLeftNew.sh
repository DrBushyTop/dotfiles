#!/bin/zsh
curWindowId="$(yabai -m query --windows --window | jq -re ".id")"

$(yabai -m window --display prev || yabai -m window --display last)
$(yabai -m window --focus "$curWindowId")
