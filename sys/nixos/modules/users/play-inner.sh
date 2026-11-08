# usage: play-inner <session dir> <display> <command> [args...]   run by play as player, never directly

dir="$1"
display="$2"
shift 2
number="${display#:}"
number="${number%%.*}"

# A private /tmp holding only the game's own display, so commander's X server in /tmp/.X11-unix is out of reach
# That display is X11 only, SDL looks for Wayland first and gives up
# Its own PID namespace and /proc, so the game can't see commander's processes and nothing it started outlives it
# A session bus of its own for the game and its sound server, without one some games start dbus-launch over and over
# Their sockets live in a private runtime folder in the session folder, Steam's wrapper hides /tmp from the game
runtime="$dir/runtime"
# shellcheck disable=SC2016  # the inner script expands inside the sandbox
exec bwrap --dev-bind / / \
    --unshare-pid \
    --proc /proc \
    --die-with-parent \
    --tmpfs /tmp \
    --dir /tmp/.X11-unix \
    --bind "/tmp/.X11-unix/X$number" "/tmp/.X11-unix/X$number" \
    --perms 0700 --tmpfs "$runtime" \
    --clearenv \
    --setenv PATH "$PATH" \
    --setenv HOME /home/player \
    --setenv USER player \
    --setenv LOGNAME player \
    --setenv DISPLAY "$display" \
    --setenv SDL_VIDEODRIVER x11 \
    --setenv XDG_RUNTIME_DIR "$runtime" \
    --setenv PULSE_RUNTIME_PATH "$runtime/pulse" \
    --setenv PULSE_SERVER "unix:$runtime/pulse/native" \
    --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=$runtime/bus" \
    --chdir /home/player \
    -- bash -c '
        dbus-daemon --session --nofork --nopidfile --address="$DBUS_SESSION_BUS_ADDRESS" > /dev/null 2>&1 &
        # Its own sound server, whose only output is the pipe back to commander
        pulseaudio -n --daemonize=no --exit-idle-time=-1 --use-pid-file=no \
            -L "module-native-protocol-unix" \
            -L "module-pipe-sink file=$0/audio format=s16le rate=48000 channels=2 sink_name=game use_system_clock_for_timing=yes" \
            > "$XDG_RUNTIME_DIR/pulseaudio.log" 2>&1 &
        for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/pulse/native" ] && [ -S "$XDG_RUNTIME_DIR/bus" ] && break; sleep 0.1; done
        [ -S "$XDG_RUNTIME_DIR/pulse/native" ] || { echo "play: no sound server, the game runs silent" >&2; cat "$XDG_RUNTIME_DIR/pulseaudio.log" >&2; }
        # Both servers end with the PID namespace once the game does
        "$@"
    ' "$dir" "$@"
