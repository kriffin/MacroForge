local W = dofile(ROOT .. "/tests/wow_stub.lua")
local realMF = MF
dofile(ROOT .. "/Profiles.lua")
-- Core redefines MF methods on the same table (NewAddon stub returns MF)
local keepPrint = MF.Print
dofile(ROOT .. "/Core.lua")
MF.Print = keepPrint; MF.modules.Profiles = MF.Profiles
local P = MF.Profiles
W.reset()
CreateMacro("A", 1, "a", true)
W.combat = true
P:CreateNewMacro("B", 1, "b", true)
P:CreateNewMacro("C", 1, "c", true)
assert(P:DeleteMacroByIndex(121) == false)
assert(P:WriteCharacterMacros({{name="X", body="x"}}) == false)
assert(W.names(true) == "A", "changed in combat")
assert(W.registered.PLAYER_REGEN_ENABLED, "no regen hook")
W.combatEnd()
assert(W.names(true) == "A,B,C", W.names(true))
assert(not W.registered.PLAYER_REGEN_ENABLED)
print("combat ok")
