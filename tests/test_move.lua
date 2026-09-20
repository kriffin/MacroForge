local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
dofile(ROOT .. "/History.lua")
local P, H = MF.Profiles, MF.modules.History
MF.modules.Profiles = P
MF.db = { char = { revisions = {} }, global = { revisions = {} }, profile = { maxHistory = 20 } }
W.reset()
CreateMacro("Acc1", 1, "a", false); CreateMacro("Kick", 1, "/cast Kick", true); CreateMacro("Other", 1, "o", true)
H:OnMacrosUpdated(); W.runTimers()
EditMacro(121, "Kick", 1, "/cast Kick\n/say x"); H:OnMacrosUpdated(); W.runTimers()
assert(#MF.db.char.revisions.Kick.versions == 2)
local kick = P:ReadCharacterMacros()[1]
assert(P:MoveMacro(kick, "account"))
H:OnMacrosUpdated(); W.runTimers()
assert(W.names(true) == "Other" and W.get(false, "Kick"), W.names(false))
local moved
for k, e in pairs(MF.db.global.revisions) do if e.name == "Kick" then moved = e end end
local stillChar
for _, e in pairs(MF.db.char.revisions) do if e.name == "Kick" then stillChar = e end end
assert(not stillChar and moved and #moved.versions == 2, "history not carried")
assert(not moved.deleted)
-- stale row refused, combat refused
assert(P:MoveMacro(kick, "account") == nil)
W.combat = true; assert(P:MoveMacro(P:ReadAccountMacros()[1], "character") == nil)
print("move ok")
