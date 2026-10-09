#!/usr/bin/env bash
# Dev tunnel to the running WoW client (see tools/bridge/MacroForgeBridge).
# Usage: tools/bridge.sh 'out(C_Spell.GetSpellName(1766))'   or   tools/bridge.sh -f query.lua
# Writes the query, presses CTRL-SHIFT-F9 (ReloadUI) in the WoW window,
# then prints what the query recorded. Takes one or two UI loads (a load
# is about a minute with many addons, and SavedVariables land ~30 s later).
# RELOAD_WAIT: seconds before a second key press when nothing landed (default 150)
set -euo pipefail
WOW_DIR=${MF_WOW_DIR:-"$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_"}
HERE=$(builtin cd "$(dirname "$0")" && pwd)
# The game loads the addon folder under Interface/AddOns (a symlink to one
# checkout): write the queue there, not next to this script (worktrees).
QUEUE="$WOW_DIR/Interface/AddOns/MacroForgeBridge/Queue.lua"
[[ -e $QUEUE || -L $QUEUE ]] || QUEUE="$HERE/bridge/MacroForgeBridge/Queue.lua"
# Several accounts on one install: the one written most recently is the one logged in
SV=$(ls -t "$WOW_DIR"/WTF/Account/*#*/SavedVariables/MacroForgeBridge.lua 2>/dev/null | head -1 || true)
[[ -z $SV ]] && SV=$(ls -td "$WOW_DIR"/WTF/Account/*#*/ 2>/dev/null | head -1)SavedVariables/MacroForgeBridge.lua

if [[ ${1:-} == -f ]]; then code=$(cat "$2"); else code=${1:?usage: bridge.sh 'lua' | -f file}; fi
id=$(date +%s%N)
level="==="; while [[ $code == *"]$level]"* ]]; do level="$level="; done
printf 'MFBridgeQueue = { id = "%s", code = [%s[\n%s\n]%s] }\n' "$id" "$level" "$code" "$level" > "$QUEUE"

export DISPLAY=${DISPLAY:-:0}
win=$(xdotool search --name '^World of Warcraft$' | head -1)
[[ -n $win ]] || { echo "WoW window not found" >&2; exit 1; }
press() { xdotool windowactivate --sync "$win"; sleep 0.4; xdotool key --clearmodifiers ctrl+shift+F9; }

press
# The addon reloads by itself once the query ran (loading can take a minute
# with many addons); a second press after a while covers a blocked reload
found=0
for i in $(seq 420); do
  if [[ -f $SV ]] && grep -q "\"$id\"" "$SV"; then found=1; break; fi
  (( i == ${RELOAD_WAIT:-150} )) && press
  sleep 1
done
(( found )) || { echo "no result for $id after 420 s (client stuck on a loading screen?)" >&2; exit 1; }
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
