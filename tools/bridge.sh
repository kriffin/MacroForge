#!/usr/bin/env bash
# Dev tunnel to the running WoW client (see tools/bridge/MacroForgeBridge).
# Usage: tools/bridge.sh 'out(C_Spell.GetSpellName(1766))'   or   tools/bridge.sh -f query.lua
# Writes the query, presses CTRL-SHIFT-ALT-F12 (ReloadUI) twice in the WoW
# window, then prints what the query recorded. Takes ~20-30 s.
# RELOAD_WAIT: seconds to wait for the UI to come back after the 1st reload (default 15)
set -euo pipefail
WOW_DIR=${MF_WOW_DIR:-"$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_"}
HERE=$(cd "$(dirname "$0")" && pwd)
QUEUE="$HERE/bridge/MacroForgeBridge/Queue.lua"
SV=$(find "$WOW_DIR/WTF/Account" -mindepth 3 -maxdepth 3 -path '*#*/SavedVariables/MacroForgeBridge.lua' | head -1 || true)
[[ -z $SV ]] && SV=$(find "$WOW_DIR/WTF/Account" -mindepth 2 -maxdepth 2 -type d -name SavedVariables -path '*#*' | head -1)/MacroForgeBridge.lua

if [[ ${1:-} == -f ]]; then code=$(cat "$2"); else code=${1:?usage: bridge.sh 'lua' | -f file}; fi
id=$(date +%s%N)
level="==="; while [[ $code == *"]$level]"* ]]; do level="$level="; done
printf 'MFBridgeQueue = { id = "%s", code = [%s[\n%s\n]%s] }\n' "$id" "$level" "$code" "$level" > "$QUEUE"

export DISPLAY=${DISPLAY:-:0}
win=$(xdotool search --name '^World of Warcraft$' | head -1)
[[ -n $win ]] || { echo "WoW window not found" >&2; exit 1; }
press() { xdotool windowactivate --sync "$win"; sleep 0.4; xdotool key --clearmodifiers ctrl+shift+alt+F12; }

press
sleep "${RELOAD_WAIT:-15}"
press
for _ in $(seq 60); do
  if [[ -f $SV ]] && grep -q "\"$id\"" "$SV"; then break; fi
  sleep 1
done
grep -q "\"$id\"" "$SV" 2>/dev/null || { echo "no result for $id (UI still loading? raise RELOAD_WAIT)" >&2; exit 1; }
lua - "$SV" <<'LUA'
local env = {}
local chunk = assert(loadfile(arg[1]))
if setfenv then setfenv(chunk, env) else chunk = load(io.open(arg[1]):read("a"), "sv", "t", env) end
chunk()
local db = env.MFBridgeDB or {}
print("# query " .. tostring(db.id) .. " at " .. tostring(db.time))
if db.error then print("ERROR: " .. db.error) end
for _, line in ipairs(db.out or {}) do print(line) end
LUA
