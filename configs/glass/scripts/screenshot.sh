#!/usr/bin/env bash
set -euo pipefail

# Fail loudly on a missing dependency
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need grim slurp wl-copy hyprctl jq

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/media/images")/screenshots"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

case "${1:-}" in
    select) grim -g "$(slurp)" "$file" ;;
    screen) grim -o "$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')" "$file" ;;
    all)    grim "$file" ;;
    *)      echo "usage: ${0##*/} select|screen|all" >&2; exit 2 ;;
esac

wl-copy < "$file"
echo "$file"
