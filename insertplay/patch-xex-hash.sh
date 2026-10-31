#!/usr/bin/env bash
# Makes a SpeedBreaker release run a modded (e.g. dubbed) PAL-ES default.xex.
#
# The runtime picks the release's recompiled code by the default.xex SHA-256.
# A modded PAL-ES xex keeps the PAL-ES code layout but has another hash, so it
# would run with the USA code and fail ("no recompiled function at the entry
# point"). This swaps the PAL-ES hash stored in lib/SpeedBreaker for the modded
# xex's hash (same length), so the runtime selects the PAL-ES code for it.
#
# Usage: patch-xex-hash.sh <speedbreaker-dir> [default.xex] [--keep-backup]
#   default.xex defaults to <speedbreaker-dir>/data/game/default.xex.
#   --keep-backup leaves the unpatched binary at lib/SpeedBreaker.orig.
set -euo pipefail

USA_SHA=aebdf3c14d1e4e4ed2c130d94bc1a0e97bd6d5bf39bdfdef33c3909c9cc4ba4c
PAL_ES_SHA=aad15fc218d034de3131f746e0b763dd8049a40dd676efc87667fcaf4fc72694

usage() { echo "Usage: $(basename "$0") <speedbreaker-dir> [default.xex] [--keep-backup]" >&2; exit 2; }

KEEP_BACKUP=0
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --keep-backup) KEEP_BACKUP=1 ;;
        -h|--help) usage ;;
        *) ARGS+=("$arg") ;;
    esac
done
[[ ${#ARGS[@]} -ge 1 && ${#ARGS[@]} -le 2 ]] || usage

SB_DIR="$(cd "${ARGS[0]}" && pwd)"
XEX="${ARGS[1]:-$SB_DIR/data/game/default.xex}"
BIN="$SB_DIR/lib/SpeedBreaker"

[[ -f "$BIN" ]] || { echo "error: $BIN not found (not a SpeedBreaker folder?)" >&2; exit 1; }
[[ -f "$XEX" ]] || { echo "error: $XEX not found" >&2; exit 1; }

XEX_SHA="$(sha256sum "$XEX" | cut -d' ' -f1)"
echo "default.xex SHA-256: $XEX_SHA"

if [[ "$XEX_SHA" == "$USA_SHA" || "$XEX_SHA" == "$PAL_ES_SHA" ]]; then
    echo "This is an official supported default.xex: no patch needed."
    exit 0
fi

python3 - "$BIN" "$PAL_ES_SHA" "$XEX_SHA" "$KEEP_BACKUP" <<'PY'
import os, shutil, sys
path, old, new, keep = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode(), sys.argv[4] == "1"
data = open(path, "rb").read()
if data.count(new) == 1 and data.count(old) == 0:
    print("Already patched for this default.xex.")
    sys.exit(0)
if data.count(old) != 1:
    sys.exit(f"error: expected the PAL-ES hash exactly once in {path}, found {data.count(old)}; "
             "this SpeedBreaker build stores it differently and can't be patched by this script")
if keep:
    shutil.copy2(path, path + ".orig")
tmp = path + ".patching"
with open(tmp, "wb") as f:
    f.write(data.replace(old, new))
shutil.copymode(path, tmp)
os.replace(tmp, path)
print(f"Patched {path}: this default.xex now runs with the PAL-ES code.")
PY
