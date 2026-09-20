local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
local keepPrint = MF.Print
dofile(ROOT .. "/Core.lua")
MF.Print = keepPrint
dofile(ROOT .. "/History.lua")
local P = MF.Profiles
MF.modules.Profiles = P
MF.db = { char = { backups = {}, revisions = {}, profiles = {
    [62] = { specName = "Arcane", macros = { { name = "Nuke", icon = 1, body = "/cast Arcane Blast" } }, timestamp = "x" },
    [63] = { specName = "Fire", macros = { { name = "Nuke", icon = 1, body = "/cast Fireball" }, { name = "Combu", icon = 1, body = "/cast Combustion" } }, timestamp = "x" },
  } }, global = { revisions = {} },
  profile = { autoSwap = true, autoSaveOnSwap = true, maxBackups = 3, maxHistory = 20 } }
W.reset()
P:MigrateProfilesToSets()
assert(MF.db.char.profiles == nil and P:GetSetForSpec(62) == "Arcane" and P:GetSetForSpec(63) == "Fire", "migration")
-- live macros = Arcane-ish, on bar
CreateMacro("Nuke", 1, "/cast Arcane Blast", true); W.place("b1", 121)
W.spec = 62; P:OnLogin()
P:ApplySet("Arcane"); assert(P:GetActiveSet() == "Arcane")
-- user edits Nuke, then swaps to Fire: edit saved into Arcane, Fire applied, bar kept
EditMacro(121, "Nuke", 1, "/cast Arcane Missiles")
W.spec = 63; P:OnSpecChanged(); W.runTimers()
assert(P:GetActiveSet() == "Fire", "swap")
assert(P:GetSets().Arcane.macros[1].body == "/cast Arcane Missiles", "autosave lost edit")
assert(W.barName("b1") == "Nuke" and W.bars.b1.body == "/cast Fireball", "bar lost")
assert(W.get(true, "Combu"))
-- duplicate event: no re-apply
local n = #W.printed; P:OnSpecChanged(); W.runTimers(); assert(#W.printed == n, "double swap")
-- swap back in combat: queued
W.spec = 62; W.combat = true; P:OnSpecChanged(); W.runTimers()
assert(W.get(true, "Combu"), "applied in combat")
W.combatEnd()
assert(not W.get(true, "Combu") and W.get(true, "Nuke").body == "/cast Arcane Missiles", "after combat")
-- binding uniqueness
P:SaveSet("PvP"); P:BindSpec("PvP", 62, true)
assert(P:GetSetForSpec(62) == "PvP" and not P:GetSets().Arcane.specs[62])
-- /mf save without name on unbound spec creates spec-named set
W.spec = 64; P:SaveCurrentProfile(""); assert(P:GetSetForSpec(64) == "Frost")
assert(P:RenameSet("Frost", "Frost2") and P:GetSetForSpec(64) == "Frost2" and P:GetActiveSet() == "Frost2")
assert(not P:RenameSet("Frost2", "PvP"))
-- restore clears active set
P:RestoreBackup(1); assert(P:GetActiveSet() == nil)
-- revisions tagged by set
H = MF.modules.History; H:OnMacrosUpdated(); W.runTimers()
print("sets ok; backups=" .. #MF.db.char.backups)
