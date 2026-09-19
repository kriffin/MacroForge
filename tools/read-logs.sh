#!/usr/bin/env bash
# Prints the MacroForge log and the BugGrabber errors from the SavedVariables.
# The client writes them on /reload, logout or exit only.
#
# Usage: tools/read-logs.sh [-n lines] [-a] [-s sessions]
#   -n N  last N log lines (default 80)
#   -a    all addon errors, not only MacroForge ones
#   -s N  errors from the last N BugGrabber sessions (default 3)
# WoW flavor dir: $MF_WOW_DIR (default: the _classic_beta_ install under the Wine prefix)
set -euo pipefail

LINES=80 ALL=0 SESSIONS=3
while getopts "n:as:" opt; do
  case $opt in
    n) LINES=$OPTARG ;;
    a) ALL=1 ;;
    s) SESSIONS=$OPTARG ;;
    *) sed -n '2,9p' "$0"; exit 1 ;;
  esac
done

WOW_DIR=${MF_WOW_DIR:-"$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_"}
SV=$(find "$WOW_DIR/WTF/Account" -mindepth 2 -maxdepth 2 -type d -name SavedVariables -path '*#*' | head -1)
[[ -n $SV ]] || { echo "No account SavedVariables under $WOW_DIR/WTF/Account" >&2; exit 1; }

lua - "$SV/MacroForge.lua" "$SV/!BugGrabber.lua" "$LINES" "$ALL" "$SESSIONS" <<'LUA'
local mfFile, bgFile, nLines, all, nSessions = arg[1], arg[2], tonumber(arg[3]), arg[4] == "1", tonumber(arg[5])

local function load(path)
  local f = io.open(path)
  if not f then return false end
  f:close()
  local ok, err = pcall(dofile, path)
  if not ok then print("!! cannot read " .. path .. ": " .. err) end
  return ok
end

print("== MacroForge log (" .. mfFile .. ")")
if load(mfFile) and type(MacroForgeLog) == "table" and MacroForgeLog.lines then
  local lines = MacroForgeLog.lines
  print(("%d lines, session #%d, debug %s"):format(#lines, MacroForgeLog.session or 0,
    MacroForgeLog.debug and "ON" or "OFF"))
  for i = math.max(1, #lines - nLines + 1), #lines do print(lines[i]) end
else
  print("(no log yet: /reload in game after installing the logging build)")
end

print("\n== BugGrabber errors (" .. (all and "all addons" or "MacroForge only")
  .. ", last " .. nSessions .. " sessions)")
if load(bgFile) and type(BugGrabberDB) == "table" and BugGrabberDB.errors then
  local current = BugGrabberDB.session or 0
  local shown = 0
  for _, e in ipairs(BugGrabberDB.errors) do
    local text = (e.message or "") .. "\n" .. (e.stack or "")
    if (e.session or 0) > current - nSessions and (all or text:find("MacroForge", 1, true)) then
      shown = shown + 1
      print(("\n-- [%s] session %s x%d"):format(e.time or "?", tostring(e.session), e.counter or 1))
      print(e.message)
      if e.stack and e.stack ~= "" then print(e.stack) end
      if e.locals and e.locals ~= "" then print("locals:\n" .. e.locals:sub(1, 1500)) end
    end
  end
  print(("\n%d error(s) shown, current session #%d, %d stored"):format(shown, current, #BugGrabberDB.errors))
else
  print("(no BugGrabber data yet)")
end
LUA
