#!/usr/bin/env bash
# Downloads an official SpeedBreaker release, verifies it, unpacks it over an
# existing SpeedBreaker folder (data/, cache/ and portable.txt are kept) and
# re-applies patch-xex-hash.sh for the folder's modded default.xex.
#
# Usage: update-speedbreaker.sh <speedbreaker-dir> [--tag vX.Y.Z] [--arch x86_64|arm64]
#   Without --tag, the latest upstream release is used.
set -euo pipefail

UPSTREAM=SpeedBreakerProject/speedbreaker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { echo "Usage: $(basename "$0") <speedbreaker-dir> [--tag vX.Y.Z] [--arch x86_64|arm64]" >&2; exit 2; }

TAG=""
ARCH=x86_64
SB_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag) TAG="${2-}"; [[ -n "$TAG" ]] || usage; shift 2 ;;
        --arch) ARCH="${2-}"; [[ "$ARCH" == x86_64 || "$ARCH" == arm64 ]] || usage; shift 2 ;;
        -h|--help) usage ;;
        *) [[ -z "$SB_DIR" ]] || usage; SB_DIR="$1"; shift ;;
    esac
done
[[ -n "$SB_DIR" ]] || usage
mkdir -p "$SB_DIR"
SB_DIR="$(cd "$SB_DIR" && pwd)"

if pgrep -f "$SB_DIR/lib/glibc/" >/dev/null 2>&1; then
    echo "error: SpeedBreaker is running from $SB_DIR; quit the game first." >&2
    exit 1
fi

ASSET="SpeedBreaker-steamos-$ARCH.tar.xz"
if [[ -n "$TAG" ]]; then
    BASE_URL="https://github.com/$UPSTREAM/releases/download/$TAG"
else
    BASE_URL="https://github.com/$UPSTREAM/releases/latest/download"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading $ASSET (${TAG:-latest})..."
curl -fsSL -o "$WORK/$ASSET" "$BASE_URL/$ASSET"
curl -fsSL -o "$WORK/$ASSET.sha256" "$BASE_URL/$ASSET.sha256"
(cd "$WORK" && sha256sum -c "$ASSET.sha256")

TOP="$(tar -tf "$WORK/$ASSET" | awk -F/ 'NR == 1 { print $1 }')"
[[ "$TOP" == SpeedBreaker ]] || { echo "error: unexpected archive layout (top folder '$TOP')" >&2; exit 1; }

echo "Unpacking over $SB_DIR..."
rm -f "$SB_DIR/lib/SpeedBreaker.orig"
tar -xf "$WORK/$ASSET" -C "$SB_DIR" --strip-components=1
echo "Installed: $(head -n 1 "$SB_DIR/VERSION" 2>/dev/null || echo 'unknown version')"

if [[ -f "$SB_DIR/data/game/default.xex" ]]; then
    "$SCRIPT_DIR/patch-xex-hash.sh" "$SB_DIR"
else
    echo "No data/game/default.xex yet: extract the game, then run patch-xex-hash.sh."
fi
