#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
target="$HOME/.config/omarchy/plugins/omarchy-stats"
mkdir -p "$target"
rsync -a --delete --delete-excluded --exclude '.git/' --exclude '__pycache__/' "$root/" "$target/"
omarchy plugin validate "$target"
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-stats --section right
omarchy bar move omarchy-stats --section right --index 1
