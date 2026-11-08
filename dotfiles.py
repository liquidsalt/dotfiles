#!/usr/bin/env python3
# usage: dotfiles nix rebuild|update, dotfiles config apply <profile>|refresh, dotfiles secrets apply <name>|refresh, dotfiles backup run|list|restore

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import tomllib
from pathlib import Path
from typing import NoReturn

REPO          = "https://github.com/liquidsalt/dotfiles"
HOME          = Path.home()
SELF          = HOME / ".local/bin/dotfiles"
CONFIG_STATE  = HOME / ".local/state/dotfiles/installed.json"
SECRETS_STATE = HOME / ".local/state/dotfiles/secrets.json"
KEYS          = HOME / ".secrets/age"  # every secrets folder's key.age, decrypted once, so backups can run unattended
BACKUP_CONFIG = HOME / ".config/dotfiles/backup.toml"
BACKUP_STATE  = HOME / ".local/state/dotfiles/backups.json"
REACH_TIMEOUT = 60  # seconds, restic itself keeps retrying a dead destination for minutes


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
    print("  backup run               back up to every destination, a dead one is skipped")
    print("  backup list              every date on every destination that's up")
    print("  backup restore <date|latest> [folder] [--over-limit]")
    print("                           restore from the first destination that has it and is under its download limit, to ~/restored/<date> by default")


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


def targets(repo: Path, tree: dict[str, tuple[str, str]], profile: str) -> tuple[dict[Path, str], dict[str, str], dict[str, str]]:
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
    merges: dict[str, str] = {}
    for src, dest in tables.get("merge", {}).items():
        if f"{base}/{src}" not in tree:
            error(f"'{src}' from {base}/map.toml is not in the repo")
        merges[f"{base}/{src}"] = dest
    return files, dconf, merges


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


# Chromium and Electron apps hold this lock while they run, a crash leaves it behind pointing at a dead pid
def app_running(dest: Path) -> bool:
    for parent in dest.parents:
        if parent == HOME:
            break
        lock = parent / "SingletonLock"
        if lock.is_symlink():
            return Path("/proc", os.readlink(lock).rpartition("-")[2]).exists()
    return False


def deep_merge(base: dict, extra: dict) -> None:
    for key, value in extra.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value


# Only the keys in the repo are set, everything else in the file stays the app's own
def merge_json(dest: Path, extra: dict) -> None:
    current = json.loads(dest.read_text()) if dest.is_file() else {}
    deep_merge(current, extra)
    write_private(dest, json.dumps(current).encode())


def install(profile: str, everything: bool) -> None:
    state = load_state(CONFIG_STATE)
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        tree = clone(repo)
        files, dconf, merges = targets(repo, tree, profile)

        if everything:
            changed = list(files)
        else:
            hashes = local_hashes(list(files))
            changed = [dest for dest, src in files.items()
                       if hashes.get(dest) != tree[src][1]
                       or os.access(dest, os.X_OK) != (tree[src][0] == "100755")]
        loads = [src for src in dconf if everything or state.get("dconf", {}).get(src) != tree[src][1]]
        merging = [src for src in merges if everything or state.get("merge", {}).get(src) != tree[src][1]]
        checkout(repo, sorted({files[d] for d in changed} | set(loads) | set(merging)))

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

        # Left unrecorded when the app is open, it would write over them on exit, so the next refresh tries again
        merged = {src: blob for src, blob in state.get("merge", {}).items() if src in merges}
        for src in merging:
            dest = HOME / merges[src]
            if app_running(dest):
                print(f"skipped {dest}, close the app and run 'dotfiles config refresh'")
                continue
            merge_json(dest, json.loads((repo / src).read_text()))
            merged[src] = tree[src][1]

        old = {HOME / p for p in state.get("files", [])}
        removed = old - set(files)
        for dest in removed:
            remove(dest)

    save_state(CONFIG_STATE, {
        "profile": profile,
        "files":   sorted(stored(d) for d in files if d not in skipped),
        "dconf":   {src: tree[src][1] for src in dconf},
        "merge":   merged,
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


def backup_config() -> dict:
    if not BACKUP_CONFIG.is_file():
        error(f"{BACKUP_CONFIG} is missing, the profile has no backups")
    return tomllib.loads(BACKUP_CONFIG.read_text())


def destinations() -> list[tuple[str, dict]]:
    return sorted(backup_config()["destinations"].items(), key=lambda d: d[1].get("priority", 99))


# Credentials and RESTIC_PASSWORD come from the destination's env file, relative to home
def read_env(path: Path) -> dict[str, str]:
    lines = (line.strip() for line in path.read_text().splitlines())
    return dict(line.split("=", 1) for line in lines if "=" in line and not line.startswith("#"))


def restic(dest: dict, *args: str, timeout: int | None = None, cwd: Path | None = None) -> subprocess.CompletedProcess:
    env = os.environ | read_env(HOME / dest["env_file"]) | {"RESTIC_REPOSITORY": dest["repo"]}
    try:
        return subprocess.run(["restic", *args], env=env, cwd=cwd, timeout=timeout, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args, 124, "", "no answer")


def must(result: subprocess.CompletedProcess) -> str:
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"restic exited with {result.returncode}")
    return result.stdout


def to_bytes(size: str) -> int:
    units = {"K": 1024, "M": 1024**2, "G": 1024**3, "T": 1024**4}
    return int(float(size[:-1]) * units[size[-1].upper()])


def repo_size(dest: dict, *snapshot: str) -> int:
    return json.loads(must(restic(dest, "stats", *snapshot, "--mode", "raw-data", "--json")))["total_size"]


# Bytes left this month, None without a limit. "2x" is twice what's stored, for providers whose free egress follows storage
def download_left(dest: dict, entry: dict) -> int | None:
    limit = dest.get("max_download")
    if limit is None:
        return None
    allowed = float(limit[:-1]) * repo_size(dest) if limit.endswith("x") else to_bytes(limit)
    return max(int(allowed) - entry.get("downloaded", {}).get(time.strftime("%Y-%m"), 0), 0)


def count_download(entry: dict, size: int) -> None:
    downloaded = entry.setdefault("downloaded", {})
    month = time.strftime("%Y-%m")
    downloaded[month] = downloaded.get(month, 0) + size


# Pruning downloads whatever it has to rewrite, so it's held to what's left of the limit
def prune_args(dest: dict, entry: dict) -> list[str]:
    left = download_left(dest, entry)
    return ["--prune"] if left is None else ["--prune", "--max-repack-size", str(left)]


# Oldest first until it fits, deduplication means a snapshot only frees what no other one uses
def trim(dest: dict, limit: int, entry: dict) -> None:
    while repo_size(dest) > limit:
        snapshots = json.loads(must(restic(dest, "snapshots", "--json")))
        if len(snapshots) <= 1:
            raise RuntimeError(f"one snapshot alone is over the limit of {dest['limit']}")
        oldest = min(snapshots, key=lambda s: s["time"])
        must(restic(dest, "forget", oldest["id"], *prune_args(dest, entry), "--max-unused", "0"))


def back_up_to(dest: dict, paths: list[str], entry: dict) -> None:
    # Exit code 10 is restic's own for a repository that doesn't exist yet, so a dead server is never initialised
    reach = restic(dest, "cat", "config", timeout=REACH_TIMEOUT)
    if reach.returncode == 10:
        must(restic(dest, "init"))
    else:
        must(reach)

    # Relative paths, so a restore lands under any home whatever the user is called
    result = restic(dest, "backup", "--exclude-caches", *paths, cwd=HOME)
    if result.returncode == 3:  # it saved all but some unreadable files
        print(result.stderr.strip(), file=sys.stderr)
    else:
        must(result)

    keep = [f"--keep-{period}={count}" for period, count in dest.get("keep", {}).items()]
    if keep:
        must(restic(dest, "forget", *prune_args(dest, entry), "--group-by", "", *keep))
    if "limit" in dest:
        trim(dest, to_bytes(dest["limit"]), entry)


def backup_run() -> None:
    paths = [p for p in backup_config()["paths"] if (HOME / p).exists()]
    state = load_state(BACKUP_STATE)
    failed = False
    for name, dest in destinations():
        entry = state.setdefault(name, {})
        try:
            back_up_to(dest, paths, entry)
            entry["last_success"] = time.strftime("%Y-%m-%d %H:%M")
            entry.pop("last_error", None)
            print(f"{name}: done")
        except RuntimeError as e:
            entry["last_error"] = str(e)
            failed = True
            print(f"{name}: {e}", file=sys.stderr)
        save_state(BACKUP_STATE, state)
    if failed:
        sys.exit(1)


# { day: [(name, destination, snapshot id)] } in priority order, restic lists oldest first so a day's last one wins
def snapshot_days() -> tuple[dict[str, list[tuple[str, dict, str]]], list[str]]:
    days: dict[str, dict[str, tuple[str, dict, str]]] = {}
    down: list[str] = []
    for name, dest in destinations():
        result = restic(dest, "snapshots", "--json", timeout=REACH_TIMEOUT)
        if result.returncode != 0:
            down.append(name)
            continue
        for snapshot in json.loads(result.stdout or "[]"):
            days.setdefault(snapshot["time"][:10], {})[name] = (name, dest, snapshot["id"])
    return {day: list(holders.values()) for day, holders in days.items()}, down


def backup_list() -> None:
    days, down = snapshot_days()
    for day in sorted(days, reverse=True):
        print(day, " ".join(name for name, _, _ in days[day]))
    for name in down:
        print(f"{name}: unreachable", file=sys.stderr)
    if not days:
        error("no snapshots on any destination that's up")


def backup_restore(date: str, folder: str | None, over_limit: bool) -> None:
    days, _ = snapshot_days()
    if date == "latest" and days:
        date = max(days)
    if date not in days:
        error(f"nothing from {date} on any destination that's up, see 'dotfiles backup list'")
    target = Path(folder).expanduser() if folder else HOME / "restored" / date
    state = load_state(BACKUP_STATE)
    for name, dest, snapshot in days[date]:
        entry = state.setdefault(name, {})
        size = repo_size(dest, snapshot)
        left = download_left(dest, entry)
        if left is not None and size > left and not over_limit:
            print(f"{name}: this needs {size} bytes and only {left} are left of its download limit this month", file=sys.stderr)
            continue
        result = restic(dest, "restore", snapshot, "--target", str(target))
        count_download(entry, size)  # a failed attempt may have downloaded it all too
        save_state(BACKUP_STATE, state)
        if result.returncode == 0:
            print(f"{date} from {name} is in {target}")
            return
        print(f"{name}: {result.stderr.strip()}", file=sys.stderr)
    error(f"no destination holding {date} could restore it, --over-limit ignores download limits")


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
    case ["backup", "run"]:
        backup_run()
    case ["backup", "list"]:
        backup_list()
    case ["backup", "restore", date, *rest]:
        folders = [a for a in rest if a != "--over-limit"]
        if len(folders) > 1:
            error("restore takes one folder")
        backup_restore(date, folders[0] if folders else None, "--over-limit" in rest)
    case ["-h" | "--help"] | []:
        print_help()
    case _:
        error(f"unknown command '{' '.join(args)}', see 'dotfiles --help'")
