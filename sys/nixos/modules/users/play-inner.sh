# usage: play-inner <session dir> <display> <command> [args...]   run by play as player, never directly

dir="$1"
display="$2"
shift 2
number="${display#:}"
number="${number%%.*}"

# A private /tmp holding only the game's own display, so commander's X server in /tmp/.X11-unix is out of reach
# shellcheck disable=SC2016  # the inner script expands inside the sandbox
exec bwrap --dev-bind / / \
    --tmpfs /tmp \
    --dir /tmp/.X11-unix \
    --bind "/tmp/.X11-unix/X$number" "/tmp/.X11-unix/X$number" \
    --dir /tmp/runtime \
    --clearenv \
    --setenv PATH "$PATH" \
    --setenv HOME /home/player \
    --setenv USER player \
    --setenv LOGNAME player \
    --setenv DISPLAY "$display" \
    --setenv XDG_RUNTIME_DIR /tmp/runtime \
    --setenv PULSE_RUNTIME_PATH /tmp/runtime/pulse \
    --setenv PULSE_SERVER unix:/tmp/runtime/pulse/native \
    --chdir /home/player \
    -- bash -c '
        # Its own sound server, whose only output is the pipe back to commander
        pulseaudio -n --daemonize=no --exit-idle-time=-1 --use-pid-file=no \
            -L "module-native-protocol-unix" \
            -L "module-pipe-sink file=$0/audio format=s16le rate=48000 channels=2 sink_name=game use_system_clock_for_timing=yes" \
            > /tmp/runtime/pulseaudio.log 2>&1 &
        for _ in $(seq 50); do [ -S /tmp/runtime/pulse/native ] && break; sleep 0.1; done
        "$@"
        status=$?
        kill %1 2>/dev/null
        exit $status
    ' "$dir" "$@"
