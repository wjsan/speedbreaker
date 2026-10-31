#!/usr/bin/env bash
# Imports Need for Speed: Most Wanted saves from Xenia into SpeedBreaker.
#
# Xenia keeps each save extracted in content/<profile>/454107D9/00000001/<name>/
# with its XCONTENT_DATA in Headers/00000001/<name>.header. SpeedBreaker keeps
# the same folder as <save dir>/<name>/ and the XCONTENT_DATA (its first 0x134
# bytes, big-endian, same layout) as <save dir>/<name>.xcontent.
#
# Usage: import-xenia-save.sh <xenia-title-dir> <speedbreaker-dir> [--region pal-es|usa]
#   <xenia-title-dir>: .../Xenia/content/<profile xuid>/454107D9
#   The region must match the disc the save was made with (default pal-es).
set -euo pipefail

usage() { echo "Usage: $(basename "$0") <xenia-title-dir> <speedbreaker-dir> [--region pal-es|usa]" >&2; exit 2; }

REGION=pal-es
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --region) REGION="${2-}"; shift 2 ;;
        -h|--help) usage ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
[[ ${#POSITIONAL[@]} -eq 2 ]] || usage
case "$REGION" in
    pal-es) SAVE_SUBDIR=save-pal-es ;;
    usa) SAVE_SUBDIR=save ;;
    *) usage ;;
esac

SRC="${POSITIONAL[0]}"
SB_DIR="${POSITIONAL[1]}"
DEST="$SB_DIR/data/$SAVE_SUBDIR"
[[ -f "$SB_DIR/portable.txt" ]] || DEST="${XDG_DATA_HOME:-$HOME/.local/share}/speedbreaker/$SAVE_SUBDIR"

[[ -d "$SRC/00000001" && -d "$SRC/Headers/00000001" ]] || { echo "error: no saves in $SRC" >&2; exit 1; }
mkdir -p "$DEST"

for header in "$SRC"/Headers/00000001/*.header; do
    name="$(basename "$header" .header)"
    if [[ ! -d "$SRC/00000001/$name" ]]; then
        echo "skip $name: no save folder"
        continue
    fi
    if [[ -e "$DEST/$name" ]]; then
        echo "skip $name: $DEST/$name already exists"
        continue
    fi
    cp -a "$SRC/00000001/$name" "$DEST/$name"
    head -c 308 "$header" > "$DEST/$name.xcontent"
    echo "imported $name -> $DEST/$name"
done
