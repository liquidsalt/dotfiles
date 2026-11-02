#!/usr/bin/env bash
# usage: sudo install-1B   wipes the disk in disk-1B.nix and installs 1B straight from the repo
set -euo pipefail

REPO="https://github.com/liquidsalt/dotfiles"  # plain git url, so any forge works
HOST="1B"
PROFILE="glass"
FLAKE="git+$REPO?shallow=1#$HOST"
DISK_PASSWORD="/tmp/disk-password"  # passwordFile in disk-1B.nix

[ "$(id -u)" -eq 0 ] || { echo "Error: run it with sudo" >&2; exit 1; }
nm-online -q -t 30 || { echo "Error: no network, connect with nmtui first" >&2; exit 1; }

tmp="$(mktemp -d)"
tailscaled_pid=""
cleanup() {
    [ -z "$tailscaled_pid" ] || { kill "$tailscaled_pid" 2>/dev/null; wait "$tailscaled_pid" 2>/dev/null; } || true
    rm -rf "$tmp" "$DISK_PASSWORD"
}
trap cleanup EXIT

heading() { printf '\n== %s ==\n' "$1"; }

# Typed in the clear so a typo shows before it is used, the prompts go to stderr and the password to stdout
ask_password() {
    local password answer
    while :; do
        read -rp "$1: " password
        [ -n "$password" ] || continue
        read -rp "Use '$password'? [y/n] " answer
        [ "$answer" = "y" ] && break
    done
    printf '%s' "$password"
}

# A failed step is retried until it works, optional ones can also be left for after the first boot
later=()
step() {
    local name="$1" after_boot="$2" answer
    shift 2
    until "$@"; do
        if [ -n "$after_boot" ]; then
            read -rp "$name failed. [r]etry, [s]kip for after the first boot, [a]bort? " answer
        else
            read -rp "$name failed. [r]etry or [a]bort? " answer
        fi
        case "$answer" in
            s) [ -z "$after_boot" ] || { later+=("$name:  $after_boot"); return 0; } ;;
            a) exit 1 ;;
        esac
    done
}

# Functions run by step use && throughout, set -e is off inside an until condition
set_password() {
    nixos-enter --root /mnt -c "chpasswd" <<< "commander:$commander_password"
}

install_profile() {
    rm -rf "$tmp/repo" &&
    git clone --quiet --depth 1 --filter=blob:none --no-checkout "$REPO" "$tmp/repo" &&
    git -C "$tmp/repo" show HEAD:dotfiles.py > "$tmp/dotfiles" &&
    install -D -m 755 "$tmp/dotfiles" /mnt/home/commander/.local/bin/dotfiles &&
    nixos-enter --root /mnt -c "chown -R commander:users /home/commander/.local" &&
    # dconf needs a session bus to write
    nixos-enter --root /mnt -c "su - commander -c 'dbus-run-session ~/.local/bin/dotfiles config apply $PROFILE'"
}

# A second tailscaled writes straight into the new system's state, the ISO's own one keeps its key in RAM
tailscale_login() {
    if [ -z "$tailscaled_pid" ]; then
        mkdir -p /mnt/var/lib/tailscale || return 1
        tailscaled --state=/mnt/var/lib/tailscale/tailscaled.state --socket="$tmp/tailscaled.sock" \
            --tun=userspace-networking --port=0 > "$tmp/tailscaled.log" 2>&1 &
        tailscaled_pid=$!
        sleep 2
    fi
    tailscale --socket="$tmp/tailscaled.sock" up --hostname="$HOST"
}

heading "Disk encryption password, asked at every boot"
(umask 077; ask_password "Disk password" > "$DISK_PASSWORD")

heading "Password for commander"
commander_password="$(ask_password "commander's password")"

heading "Partitioning, disko asks before wiping"
step "Partitioning" "" disko --mode destroy,format,mount --flake "$FLAKE"
rm -f "$DISK_PASSWORD"

heading "Installing NixOS"
step "Installing NixOS" "" nixos-install --flake "$FLAKE" --no-root-passwd

step "Setting commander's password" "" set_password
unset commander_password

# Folders from tmpfiles normally appear at boot, the profile needs some of them now
nixos-enter --root /mnt -c "systemd-tmpfiles --create" > /dev/null 2>&1 || true  # rules for /run and /dev fail outside a booted system

heading "Profile $PROFILE"
step "Profile" "git clone --depth 1 $REPO /tmp/dotfiles && python3 /tmp/dotfiles/dotfiles.py config apply $PROFILE" install_profile

heading "Secrets, asks the age keys' passphrase, shown as you type"
step "Secrets" "dotfiles secrets apply $HOST" \
    nixos-enter --root /mnt -c "su - commander -c '~/.local/bin/dotfiles secrets apply $HOST'"

heading "Tailscale login for $HOST, open the link on another device"
step "Tailscale" "sudo tailscale up --hostname=$HOST" tailscale_login

if [ "${#later[@]}" -gt 0 ]; then
    heading "Left for after the first boot, in this order"
    printf '%s\n' "${later[@]}"
fi

echo
echo "Done, reboot when ready"
