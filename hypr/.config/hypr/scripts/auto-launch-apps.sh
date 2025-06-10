#!/usr/bin/env bash

# Define setups: (workspace command) pairs
declare -A SETUPS
SETUPS["🛠 Admin"]="2:firefox|4:kitty -e nvim|1:flatpak run eu.betterbird.Betterbird"
SETUPS["🌐 Browsing"]="2:firefox|3:kitty -e yazi|4:kitty -e tmuxifier load-session config"
SETUPS["🧱 Civil"]="4:kitty -e tmuxifier load-session cc-dev|1:flatpak run eu.betterbird.Betterbird|5:slack"
SETUPS["🗂 Files"]="3:dolphin|4:kitty -e yazi"
SETUPS["🧩 Game Mods"]="2:steam|4:kitty -d ~/.steam/steam/steamapps/ yazi|3:kitty -d ~/Downloads/ yazi"
SETUPS["🎮 Game"]="2:steam"
SETUPS["📅 Meeting"]="5:firefox https://calendar.google.com/|7:firefox"
SETUPS["📊 System Monitor"]="4:kitty -e btop|3:kitty -e journalctl -f"
SETUPS["🛡️ DNF Update"]="3:kitty -e journalctl -f|2:kitty -e sysup"
SETUPS["💼 Work"]="2:firefox|4:kitty -e tmuxifier load-session uphill|1:flatpak run eu.betterbird.Betterbird|5:slack"

# Prompt selection
CHOICE=$(printf "%s\n" "${!SETUPS[@]}" | wofi --dmenu --columns 1 -p "Select session")
[[ -z "$CHOICE" ]] && exit 0

# Launch each app silently on specific workspace
IFS='|' read -ra PAIRS <<<"${SETUPS["$CHOICE"]}"
for pair in "${PAIRS[@]}"; do
  WS="${pair%%:*}"
  CMD="${pair#*:}"
  echo "DEBUG: [workspace $WS silent] $CMD"
  hyprctl dispatch exec "[workspace $WS silent] $CMD"
done
