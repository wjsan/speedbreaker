#!/usr/bin/env python3
"""Extracts an Xbox 360 disc image (XISO or full Redump ISO) to a folder.

SpeedBreaker's installer only takes the official USA and PAL-ES discs; a modded
disc is extracted with this instead and started by passing its default.xex
to speedbreaker.sh (see README.md).

Usage: extract-xiso.py <image.iso> <dest-dir>      extract every file
       extract-xiso.py <image.iso>                 list files and sizes
"""
import os
import struct
import sys

SECTOR = 2048
MAGIC = b"MICROSOFT*XBOX*MEDIA"
# XISO, XGD2 (full Redump), XGD1, XGD3 game partition offsets.
PARTITIONS = (0, 0xFD90000, 0x18300000, 0x2080000)


def find_partition(f):
    for base in PARTITIONS:
        f.seek(base + 32 * SECTOR)
        if f.read(len(MAGIC)) == MAGIC:
            return base
    sys.exit("error: not an Xbox 360 disc image (no XDVDFS volume found)")


def walk(f, base, sector, size, path, out):
    f.seek(base + sector * SECTOR)
    table = f.read(size)
    pending, seen = [0], set()
    while pending:
        offset = pending.pop()
        if offset in seen or offset * 4 + 14 > len(table):
            continue
        seen.add(offset)
        left, right, start, length, attr, name_len = struct.unpack_from("<HHIIBB", table, offset * 4)
        if left == 0xFFFF:
            continue
        name = table[offset * 4 + 14:offset * 4 + 14 + name_len].decode("latin-1")
        if left:
            pending.append(left)
        if right:
            pending.append(right)
        child = f"{path}/{name}" if path else name
        if attr & 0x10:
            walk(f, base, start, length, child, out)
        else:
            out.append((child, start, length))


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    with open(sys.argv[1], "rb") as f:
        base = find_partition(f)
        f.seek(base + 32 * SECTOR + len(MAGIC))
        root_sector, root_size = struct.unpack("<II", f.read(8))
        files = []
        walk(f, base, root_sector, root_size, "", files)
        if len(sys.argv) == 2:
            for path, _, length in sorted(files):
                print(length, path)
            return
        dest = sys.argv[2]
        for i, (path, start, length) in enumerate(sorted(files), 1):
            target = os.path.join(dest, path)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            print(f"[{i}/{len(files)}] {path}", flush=True)
            f.seek(base + start * SECTOR)
            remaining = length
            with open(target, "wb") as out:
                while remaining:
                    chunk = f.read(min(remaining, 8 << 20))
                    if not chunk:
                        sys.exit(f"error: image truncated while reading {path}")
                    out.write(chunk)
                    remaining -= len(chunk)


if __name__ == "__main__":
    main()
