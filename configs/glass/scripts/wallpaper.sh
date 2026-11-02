#!/usr/bin/env bash
set -euo pipefail

# Fail loudly on a missing dependency
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need jq

state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/wallpapers.json"
mkdir -p "$(dirname "$state")"
[ -f "$state" ] || echo '{}' > "$state"

# mpvpaper for video, awww for everything else
apply() {
    local out="$1" path="$2"
    case "${path,,}" in
        *.mp4|*.mkv|*.webm|*.avi|*.mov)
            need mpvpaper
            pkill -f "mpvpaper.* $out " 2>/dev/null || true
            mpvpaper -o "no-audio loop" "$out" "$path" &
        ;;
        *)
            need awww
            awww img --outputs "$out" "$path"
        ;;
    esac
}


case "${1:-}" in
    set)
        out="${2:?usage: ${0##*/} set <output> <path>}"
        path="${3:?usage: ${0##*/} set <output> <path>}"
        [ -f "$path" ] || { echo "no such file: $path" >&2; exit 1; }
        apply "$out" "$path"
        jq --arg o "$out" --arg p "$path" '.[$o] = { path: $p }' "$state" > "$state.tmp"
        mv "$state.tmp" "$state"
    ;;

    restore)
        while IFS=$'\t' read -r out path; do
            [ -f "$path" ] && apply "$out" "$path"
        done < <(jq -r 'to_entries[] | "\(.key)\t\(.value.path)"' "$state")
    ;;

    *)
        echo "usage: ${0##*/} set <output> <path> | restore" >&2
        exit 2
    ;;
esac
