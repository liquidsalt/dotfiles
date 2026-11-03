#!/usr/bin/env python3
# usage: dotfiles nix rebuild|update, dotfiles config apply <profile>|refresh, dotfiles secrets apply <name>|refresh

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import NoReturn

REPO          = "https://github.com/liquidsalt/dotfiles"
HOME          = Path.home()
SELF          = HOME / ".local/bin/dotfiles"
CONFIG_STATE  = HOME / ".local/state/dotfiles/installed.json"
SECRETS_STATE = HOME / ".local/state/dotfiles/secrets.json"
KEYS          = HOME / ".secrets/age"  # every secrets folder's key.age, decrypted once, so backups can run unattended


def error(msg: str) -> NoReturn:
    print(f"dotfiles: {msg}", file=sys.stderr)
    sys.exit(1)


def run(*cmd: str, cwd: Path | None = None, stdin: str | None = None) -> str:
    result = subprocess.run(cmd, cwd=cwd, input=stdin, capture_output=True, text=True)
    if result.returncode != 0:
        error(f"{' '.join(cmd[:2])} failed\n{result.stderr.strip()}")
    return result.stdout


def print_help() -> None:
    print("usage: dotfiles <group> <action>")
    print("  nix rebuild              rebuild NixOS from the repo")
    print("  nix update               update the flake lock and push it")
    print("  config apply <profile>   install a profile, replacing the current one")
    print("  config refresh           update the current profile, only changed files are downloaded")
    print("  secrets apply <name>     unlock the keys and decrypt common and the named secrets, asks the passphrase")
    print("  secrets refresh          decrypt again whatever changed with the keys already here")


# A specialisation doesn't know its own name, only the generations holding it do, None on the base system
def current_specialisation() -> str | None:
    running = Path("/run/current-system").resolve()
    for link in Path("/nix/var/nix/profiles").glob("system-*-link/specialisation/*"):
        if link.resolve() == running:
            return link.name
    return None


def nix_rebuild() -> None:
    host = socket.gethostname()
    cmd = ["sudo", "nixos-rebuild", "switch", "--refresh", "--flake", f"git+{REPO}?shallow=1#{host}"]
    specialisation = current_specialisation()
    if specialisation:
        cmd += ["--specialisation", specialisation]
    os.execvp("sudo", cmd)


# No local copy, so the lock is updated in a throwaway clone and pushed from there
def nix_update() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        run("git", "clone", "--quiet", "--depth", "1", REPO, str(repo))
        subprocess.run(["nix", "flake", "update", "--flake", str(repo)], check=True)
        if subprocess.run(["git", "diff", "--quiet", "flake.lock"], cwd=repo).returncode == 0:
            print("Already up to date")
            return
        run("git", "commit", "--quiet", "-m", "Update flake inputs", "flake.lock", cwd=repo)
        subprocess.run(["git", "push", "--quiet"], cwd=repo, check=True)


# Only names and hashes come down here, file contents are fetched later by checkout()
def clone(repo: Path) -> dict[str, tuple[str, str]]:
    run("git", "clone", "--quiet", "--depth", "1", "--filter=blob:none",
        "--no-checkout", "--sparse", REPO, str(repo))
    tree: dict[str, tuple[str, str]] = {}
    for line in run("git", "ls-tree", "-r", "HEAD", cwd=repo).splitlines():
        meta, path = line.split("\t", 1)
        mode, _, blob = meta.split()
        tree[path] = (mode, blob)
    return tree


def checkout(repo: Path, paths: list[str]) -> None:
    # Sparse patterns are gitignore syntax, so special characters in file names need escaping
    patterns = ["/" + "".join("\\" + c if c in "*?[]\\!#" else c for c in p) for p in paths]
    run("git", "sparse-checkout", "set", "--no-cone", "--stdin", cwd=repo, stdin="\n".join(patterns))
    run("git", "checkout", "--quiet", cwd=repo)


def read_map(repo: Path, base: str) -> dict:
    try:
        return tomllib.loads(run("git", "show", f"HEAD:{base}/map.toml", cwd=repo))
    except tomllib.TOMLDecodeError as e:
        error(f"{base}/map.toml is invalid: {e}")


# Destination -> repo path, sources are relative to map.toml and folders are expanded to their files
def expand(tree: dict[str, tuple[str, str]], base: str, table: dict[str, str], suffix: str = "") -> dict[Path, str]:
    files: dict[Path, str] = {}
    for src, dest in table.items():
        path = f"{base}/{src}"
        if path in tree:
            files[HOME / dest] = path
            continue
        inside = [p for p in tree if p.startswith(path + "/")]
        if not inside:
            error(f"'{src}' from {base}/map.toml is not in the repo")
        for p in inside:
            files[HOME / dest / p.removeprefix(path + "/").removesuffix(suffix)] = p
    return files


def targets(repo: Path, tree: dict[str, tuple[str, str]], profile: str) -> tuple[dict[Path, str], dict[str, str]]:
    base = f"configs/{profile}"
    if f"{base}/map.toml" not in tree:
        error(f"no profile named '{profile}'")
    tables = read_map(repo, base)

    files = {SELF: "dotfiles.py"} | expand(tree, base, tables.get("files", {}))
    dconf: dict[str, str] = {}
    for src, prefix in tables.get("dconf", {}).items():
        if f"{base}/{src}" not in tree:
            error(f"'{src}' from {base}/map.toml is not in the repo")
        dconf[f"{base}/{src}"] = prefix  # the dconf path it is loaded under
    return files, dconf


# common/ always comes first, so the named set can override it
def secret_targets(repo: Path, tree: dict[str, tuple[str, str]], name: str) -> dict[Path, str]:
    if f"secrets/{name}/map.toml" not in tree:
        error(f"no secrets named '{name}'")
    files: dict[Path, str] = {}
    for base in dict.fromkeys(["secrets/common", f"secrets/{name}"]):
        if f"{base}/map.toml" in tree:
            files |= expand(tree, base, read_map(repo, base), suffix=".age")  # files in a mapped folder lose .age
    return files


# The same hash git gives a file, so local files can be compared with the repo without downloading it
def local_hashes(paths: list[Path]) -> dict[Path, str]:
    present = [p for p in paths if p.is_file()]
    if not present:
        return {}
    out = run("git", "hash-object", "--stdin-paths", stdin="\n".join(map(str, present)))
    return dict(zip(present, out.split(), strict=True))


def load_state(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2) + "\n")


# map.toml destinations are relative to home, or absolute for the few places outside it
def stored(dest: Path) -> str:
    return str(dest.relative_to(HOME)) if dest.is_relative_to(HOME) else str(dest)


def remove(dest: Path) -> None:
    dest.unlink(missing_ok=True)
    # Clear folders left empty, but only inside home
    for parent in dest.parents:
        if parent == HOME or not parent.is_relative_to(HOME) or not parent.is_dir() or any(parent.iterdir()):
            break
        parent.rmdir()


def install(profile: str, everything: bool) -> None:
    state = load_state(CONFIG_STATE)
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        tree = clone(repo)
        files, dconf = targets(repo, tree, profile)

        if everything:
            changed = list(files)
        else:
            hashes = local_hashes(list(files))
            changed = [dest for dest, src in files.items()
                       if hashes.get(dest) != tree[src][1]
                       or os.access(dest, os.X_OK) != (tree[src][0] == "100755")]
        loads = [src for src in dconf if everything or state.get("dconf", {}).get(src) != tree[src][1]]
        checkout(repo, sorted({files[d] for d in changed} | set(loads)))

        # Outside home only goes where the system made a writable folder, other systems just skip it
        skipped: set[Path] = set()
        for dest in changed:
            src = files[dest]
            part = dest.with_name(dest.name + ".part")
            try:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(repo / src, part)
            except PermissionError:
                if dest.is_relative_to(HOME):
                    error(f"can't write {dest}")
                skipped.add(dest)
                continue
            part.chmod(0o755 if tree[src][0] == "100755" else 0o644)
            part.replace(dest)
        for folder in sorted({d.parent for d in skipped}):
            print(f"skipped {folder}, it isn't writable here")

        for src in loads:
            run("dconf", "load", dconf[src], stdin=(repo / src).read_text())

        old = {HOME / p for p in state.get("files", [])}
        removed = old - set(files)
        for dest in removed:
            remove(dest)

    save_state(CONFIG_STATE, {
        "profile": profile,
        "files":   sorted(stored(d) for d in files if d not in skipped),
        "dconf":   {src: tree[src][1] for src in dconf},
    })
    print(f"{profile}: {len(changed) - len(skipped)} updated, {len(removed)} removed, {len(loads)} dconf loaded")


def write_private(dest: Path, data: bytes) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    part = dest.with_name(dest.name + ".part")
    with os.fdopen(os.open(part, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "wb") as f:
        f.write(data)
    part.replace(dest)


def decrypt(args: list[str], what: str) -> bytes:
    result = subprocess.run(["age", "-d", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        error(f"could not decrypt {what}\n{result.stderr.decode().strip()}")
    return result.stdout


# age's own prompt hides what's typed, batchpass takes the passphrase from a pipe instead
def unlock_key(path: Path, passphrase: str) -> bytes | None:
    read, write = os.pipe()
    os.write(write, passphrase.encode())
    os.close(write)
    result = subprocess.run(["age", "-d", "-j", "batchpass", str(path)], capture_output=True,
                            env=os.environ | {"AGE_PASSPHRASE_FD": str(read)}, pass_fds=(read,))
    os.close(read)
    return result.stdout if result.returncode == 0 else None


# Each folder has its own key, so a machine only ever holds the keys for the folders it uses
def secrets(name: str, everything: bool) -> None:
    state = load_state(SECRETS_STATE)
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        tree = clone(repo)
        files = secret_targets(repo, tree, name)

        folders = list(dict.fromkeys(["common", name]))
        for src in files.values():
            if f"secrets/{src.split('/')[1]}/key.age" not in tree:
                error(f"secrets/{src.split('/')[1]} has no key.age")
        keys = {f: tree[f"secrets/{f}/key.age"][1] for f in folders if f"secrets/{f}/key.age" in tree}
        # apply starts fresh from key.age, refresh only asks when a key is missing or key.age changed
        unlock = [f for f in keys if everything or not (KEYS / f"{f}.key").is_file() or state.get("keys", {}).get(f) != keys[f]]

        known = state.get("files", {}) if state.get("name") == name else {}
        changed = [dest for dest, src in files.items()
                   if everything or not dest.is_file() or known.get(stored(dest)) != tree[src][1]]
        checkout(repo, sorted({files[d] for d in changed} | {f"secrets/{f}/key.age" for f in unlock}))

        # Every key.age shares one passphrase, so it's asked once and shown as it's typed
        passphrase = ""
        for f in unlock:
            key = None
            for _ in range(3):
                passphrase = passphrase or input("Passphrase for the age keys: ")
                key = unlock_key(repo / f"secrets/{f}/key.age", passphrase)
                if key is not None:
                    break
                print("Wrong passphrase", file=sys.stderr)
                passphrase = ""
            if key is None:
                error(f"could not unlock secrets/{f}/key.age")
            write_private(KEYS / f"{f}.key", key)
        for f in set(state.get("keys", {})) - set(keys):
            (KEYS / f"{f}.key").unlink(missing_ok=True)

        for dest in changed:
            src = files[dest]
            key = KEYS / f"{src.split('/')[1]}.key"
            write_private(dest, decrypt(["-i", str(key), str(repo / src)], src))

        removed = {HOME / p for p in state.get("files", {})} - set(files)
        for dest in removed:
            remove(dest)

    save_state(SECRETS_STATE, {
        "name":  name,
        "keys":  keys,
        "files": {stored(d): tree[src][1] for d, src in files.items()},
    })
    print(f"{name}: {len(unlock)} keys unlocked, {len(changed)} decrypted, {len(removed)} removed")


args = sys.argv[1:]
match args:
    case ["nix", "rebuild"]:
        nix_rebuild()
    case ["nix", "update"]:
        nix_update()
    case ["config", "apply", profile]:
        install(profile, everything=True)
    case ["config", "refresh"]:
        profile = load_state(CONFIG_STATE).get("profile") or error("nothing applied yet, run 'dotfiles config apply <profile>'")
        install(profile, everything=False)
    case ["secrets", "apply", name]:
        secrets(name, everything=True)
    case ["secrets", "refresh"]:
        name = load_state(SECRETS_STATE).get("name") or error("nothing applied yet, run 'dotfiles secrets apply <name>'")
        secrets(name, everything=False)
    case ["-h" | "--help"] | []:
        print_help()
    case _:
        error(f"unknown command '{' '.join(args)}', see 'dotfiles --help'")
