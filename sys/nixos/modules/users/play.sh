# usage: play <command> [args...]   runs a game as player inside gamescope, it only sees its own window and an audio pipe out
# play_inner is set above this line by player.nix

[ $# -gt 0 ] || { echo "usage: play <command> [args...]" >&2; exit 2; }

dir="$(mktemp -d /run/play/XXXXXX)"
tunnel=""
cleanup() {
    [ -z "$tunnel" ] || kill "$tunnel" 2>/dev/null || true
    rm -rf "$dir"
}
trap cleanup EXIT
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

# sudo resets the environment, so the game's display goes in as an argument
# shellcheck disable=SC2016  # $DISPLAY is gamescope's, so it expands inside it
gamescope "${gpu[@]}" -- bash -c 'exec /run/wrappers/bin/sudo -n -u player "$0" "$1" "$DISPLAY" "${@:2}"' \
    "$play_inner" "$dir" "$@"
