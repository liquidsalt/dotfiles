#!/usr/bin/env python3
# usage: nari-essential-battery [--raw]
# Prints "85% discharging", "charging", "full", "off" or "no dongle", and exits 1 when off or unplugged

import fcntl
import glob
import os
import sys
import time

DONGLE = "051E"  # wireless receiver
CABLE  = "051F"  # headset itself, only present while on its USB cable
SIZE   = 64
QUERY  = bytes([0xFF, 0x0A, 0x00, 0xFD, 0x04, 0x12, 0xF1, 0x02, 0x05])

# Byte 9 of the reply, FULL once the LED turns green
BATTERY, CHARGING, FULL = 0x03, 0x05, 0x06

# Resting single-cell Li-ion voltage (mV) to percent
# The top is measured, straight off a full charge this headset reads 4110 and not the textbook 4200
CURVE = [(4110, 100), (4000, 80), (3930, 70), (3870, 60),
         (3830, 50), (3790, 40), (3770, 30), (3740, 20), (3680, 10),
         (3500, 5), (3300, 0)]

# _IOC(READ|WRITE, 'H', nr, SIZE) from linux/hidraw.h
SFEATURE = (3 << 30) | (SIZE << 16) | (ord("H") << 8) | 0x06
GFEATURE = (3 << 30) | (SIZE << 16) | (ord("H") << 8) | 0x07


def nodes(pid):
    tag = "0003:00001532:0000" + pid
    for node in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        try:
            with open(node + "/device/uevent") as fh:
                if tag in fh.read().upper():
                    yield "/dev/" + os.path.basename(node)
        except OSError:
            pass


def frame(path):
    fd = os.open(path, os.O_RDWR)
    try:
        buf = bytearray(QUERY.ljust(SIZE, b"\0"))
        fcntl.ioctl(fd, SFEATURE, buf)
        buf = bytearray(b"\xff".ljust(SIZE, b"\0"))
        fcntl.ioctl(fd, GFEATURE, buf)
        return bytes(buf)
    finally:
        os.close(fd)


def reading(path):
    # (millivolts, state). Byte 14 isn't a level, it stays put through a whole charge
    # While charging the voltage is pinned near 4200, so there's no percentage until unplugged
    for attempt in range(3):  # a just-woken headset answers zeros at first
        if attempt:
            time.sleep(0.2)
        buf = frame(path)
        mv = (buf[12] << 8) | buf[13]
        if mv:
            return mv, buf[9]
    return 0, None


def read(pid):
    for path in nodes(pid):
        try:
            mv, state = reading(path)
        except PermissionError:
            sys.exit("%s: permission denied, check the udev rule" % path)
        except OSError:
            continue  # wrong HID interface, or unplugged mid-read
        if mv:
            return mv, state
    return 0, None


def percent(mv):
    if mv >= CURVE[0][0]:
        return 100
    for (hv, hp), (lv, lp) in zip(CURVE, CURVE[1:]):
        if mv >= lv:
            return round(lp + (mv - lv) * (hp - lp) / (hv - lv))
    return 0


# --raw dumps the whole reply from every matching node, for reverse engineering
if sys.argv[1:] == ["--raw"]:
    for pid in (DONGLE, CABLE):
        for path in nodes(pid):
            try:
                print(pid, path, frame(path).hex(" "))
            except OSError as exc:
                print(pid, path, exc)
    sys.exit(0)

def charge(state):
    print("full" if state == FULL else "charging")
    sys.exit(0)


if any(nodes(CABLE)):
    charge(read(CABLE)[1])

if not any(nodes(DONGLE)):
    print("no dongle")
    sys.exit(1)

mv, state = read(DONGLE)
if not mv:
    print("off")
    sys.exit(1)

# The dongle repeats the headset's last report, so for a few seconds after unplugging it still says charging
if state != BATTERY:
    charge(state)

print("%d%% discharging" % percent(mv))
