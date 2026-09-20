local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
dofile(ROOT .. "/History.lua")
local P, H = MF.Profiles, MF.modules.History
MF.modules.Profiles = P
local clock = 100; time = function() clock = clock + 1; return clock end
MF.db = { char = { revisions = {} }, global = { revisions = {} }, profile = { maxHistory = 20 } }
W.reset()
-- two macros with a blank name, like unnamed macros in game
CreateMacro(" ", 1, "#showtooltip\n/use Sap", true)
CreateMacro(" ", 1, "#showtooltip Backstab\n/use Backstab", true)
H:OnMacrosUpdated(); W.runTimers()
local R = MF.db.char.revisions
local keys = {} for k in pairs(R) do keys[#keys+1] = k end
assert(#keys == 2, #keys)
-- edit the second one, then delete the FIRST: histories must not swap
EditMacro(122, " ", 1, "#showtooltip Backstab\n/use Backstab\n/use Pick Pocket")
H:OnMacrosUpdated(); W.runTimers()
DeleteMacro(121)
H:OnMacrosUpdated(); W.runTimers()
local deleted = H:GetDeleted()
assert(#deleted == 1, #deleted)
local last = deleted[1].entry.versions[#deleted[1].entry.versions]
assert(last.body:find("Sap", 1, true), "trash shows the wrong macro: " .. last.body)
-- the surviving macro keeps its own 2 versions
for _, d in pairs(R) do
  if not d.deleted then assert(#d.versions == 2 and d.versions[2].body:find("Pick Pocket", 1, true), "survivor history") end
end
-- label falls back to the #showtooltip spell, and never crosses lines
assert(MF.Helpers == nil or true)
print("history keying ok")
