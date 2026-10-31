#!/usr/bin/env bash
set -e

set -x

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SD_ROOT="$BASE_DIR"
while [[ ! -f "$SD_ROOT/autorun.sh" && "$SD_ROOT" != "/" ]]; do
    SD_ROOT="$(dirname "$SD_ROOT")"
done

if [[ -f "$SD_ROOT/insertplay-guid-guard.sh" ]]; then
    source "$SD_ROOT/insertplay-guid-guard.sh"
    insertplay_guard_verify_or_exit "$SD_ROOT" "$@"
fi

echo "Script running from: $BASE_DIR"

# SpeedBreaker (native static recompilation) in portable mode: saves, settings,
# logs, caches and the extracted game all live in speedbreaker/.
SPEEDBREAKER="$BASE_DIR/speedbreaker/speedbreaker.sh"
# The dubbed PAL-ES default.xex isn't accepted by the installer, so it is passed
# directly to the runtime (lib/SpeedBreaker is patched to treat its hash as PAL-ES).
GAME_XEX="$BASE_DIR/speedbreaker/data/game/default.xex"

if [ ! -f "$SPEEDBREAKER" ]; then
    echo "SpeedBreaker not found at $SPEEDBREAKER"
    exit 1
fi

if [ ! -f "$GAME_XEX" ]; then
    echo "Game not found at $GAME_XEX"
    exit 1
fi

chmod +x "$SPEEDBREAKER"

echo "Launching SpeedBreaker..."
exec "$SPEEDBREAKER" "$GAME_XEX"
