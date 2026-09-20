local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
local keepPrint = MF.Print
dofile(ROOT .. "/Core.lua")
MF.Print = keepPrint
dofile(ROOT .. "/History.lua")
local H = MF.modules.History
MF.modules.Profiles = MF.Profiles
local clock = 1000
time = function() return clock end
MF.db = { char = { backups = {}, revisions = {} }, global = { revisions = {} }, profile = { maxHistory = 3 } }
W.reset()
local function tick() clock = clock + 1; H:OnMacrosUpdated(); W.runTimers() end
CreateMacro("A", 1, "a1", true); CreateMacro("Dup", 1, "d1", true); CreateMacro("Dup", 1, "d2", true)
CreateMacro("Acc", 1, "x", false)
tick()
local R = MF.db.char.revisions
assert(R.A and R.Dup and R["Dup#2"] and MF.db.global.revisions.Acc, "initial keys")
-- edits outside the addon are captured, deduped, capped
for i = 2, 6 do EditMacro(121, "A", 1, "a" .. i); tick() end
tick() -- no change: no new version
assert(#R.A.versions == 3 and R.A.versions[3].body == "a6", #R.A.versions)
-- delete -> tombstone with versions kept
DeleteMacro(121); tick()
assert(R.A.deleted and #R.A.versions == 3, "tombstone")
local del = H:GetDeleted(); assert(#del == 1 and del[1].key == "A")
-- recreate with same name -> history continues
CreateMacro("A", 1, "a7", true); tick()
assert(not R.A.deleted and R.A.versions[3].body == "a7")
-- rename keeps versions
local idx = 120 + 3  -- find A
for i = 121, 123 do if GetMacroInfo(i) == "A" then idx = i end end
EditMacro(idx, "Renamed", 1, "a7"); tick()
-- the key is a stable id now: the entry keeps its key and records the new name
assert(R.A and R.A.name == "Renamed" and R.A.versions[#R.A.versions].name == "Renamed", "rename")
-- reason tagging
H:SetNextReason("set: Raid"); EditMacro(121, "Dup", 1, "d1b"); tick()
assert(R.Dup.versions[#R.Dup.versions].reason == "set: Raid")
-- migration from index-keyed history
MF.db.char.history = { ["121"] = { { name = "Dup", body = "old", icon = 1, timestamp = "2025-01-01" } } }
tick()
assert(MF.db.char.history == nil and R.Dup.versions[1].body == "old" and R.Dup.versions[1].stamp)
-- deleted pruning
for i = 1, 60 do CreateMacro("T" .. i, 1, "t" .. i, false) end; tick()
for i = 1, 60 do DeleteMacro(2) end; tick()
local n = 0 for _, e in pairs(MF.db.global.revisions) do if e.deleted then n = n + 1 end end
assert(n == 50, n)
print("history ok")
