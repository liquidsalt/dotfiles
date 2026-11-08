# usage: [PLAY_BACKEND=wayland] play <command> [args...]   runs a game as player inside gamescope, it only sees its own window and an audio pipe out
# play_inner is set above this line by player.nix

[ $# -gt 0 ] || { echo "usage: play <command> [args...]" >&2; exit 2; }

dir="$(mktemp -d /run/play/XXXXXX)"
unit="play-$(basename "$dir")"
tunnel=""
# commander can't signal player's processes, but can empty the scope they run in, so nothing the game started outlives it
cleanup() {
    [ -z "$tunnel" ] || kill "$tunnel" 2>/dev/null || true
    group="$(systemctl --user show -P ControlGroup "$unit.scope" 2>/dev/null || true)"
    [ -z "$group" ] || echo 1 > "/sys/fs/cgroup$group/cgroup.kill" 2>/dev/null || true
    rm -rf "$dir"
}
trap cleanup EXIT
trap "exit 130" INT TERM HUP  # so closing the terminal still runs cleanup
chmod 2770 "$dir"

# The game's sound comes out of this pipe and plays here like any other app, nothing goes the other way
pw-cli -m load-module libpipewire-module-pipe-tunnel "{
    tunnel.mode = playback  pipe.filename = \"$dir/audio\"
    audio.format = S16LE  audio.rate = 48000  audio.channels = 2  audio.position = [ FL FR ]
    node.name = play-$(basename "$dir")  node.description = \"play: $(basename "$1")\"
}" > /dev/null &
tunnel=$!
for _ in $(seq 50); do [ -p "$dir/audio" ] && break; sleep 0.1; done
[ -p "$dir/audio" ] || { echo "play: the audio pipe didn't appear" >&2; exit 1; }
chmod 660 "$dir/audio"

# gamescope has to render on the GPU Hyprland uses, the first one in AQ_DRM_DEVICES
gpu=()
first="${AQ_DRM_DEVICES%%:*}"
if [ -n "$first" ] && [ -e "$first" ]; then
    device="/sys/class/drm/$(basename "$(readlink -f "$first")")/device"
    gpu=(--prefer-vk-device "$(sed 's/^0x//' "$device/vendor"):$(sed 's/^0x//' "$device/device")")
fi

# Rendered at the focused monitor's size and rate, so a tiled or floating window only scales it and fullscreen is native
size=()
if monitor="$(hyprctl monitors -j 2>/dev/null | jq -er '.[] | select(.focused) | "\(.width) \(.height) \(.refreshRate | round)"')"; then
    read -r width height rate <<< "$monitor"
    size=(-W "$width" -H "$height" -w "$width" -h "$height" -r "$rate")
fi

# Always composited, a game buffer passed straight through to Hyprland only gets redrawn around the cursor
# Its SDL window by default, the Wayland one left Elden Ring frozen once the focus went to another monitor, PLAY_BACKEND=wayland picks it per launch
# Its own scope, capped so a game that forks without end only fills that and not commander's session
# gamescope's X server only lets commander in, player is let in on this one display only
# gamescope can't signal player's processes, so its child empties the scope when the window closes or the game ends, nothing is left to wait for
# sudo resets the environment, so the game's display goes in as an argument
# shellcheck disable=SC2016  # $DISPLAY is gamescope's, so it expands inside it
systemd-run --user --scope --quiet --unit="$unit" -p TasksMax=8192 \
    gamescope --backend "${PLAY_BACKEND:-sdl}" --force-composition "${gpu[@]}" "${size[@]}" -- bash -c '
        trap "echo 1 > /sys/fs/cgroup$(cut -d: -f3 /proc/self/cgroup)/cgroup.kill" EXIT TERM INT HUP
        xhost +SI:localuser:player > /dev/null || exit 1
        /run/wrappers/bin/sudo -n -u player "$0" "$1" "$DISPLAY" "${@:2}" &
        wait $!
    ' "$play_inner" "$dir" "$@" &

# In the background so a kill or ctrl+c reaches the trap right away instead of after gamescope
wait $!
