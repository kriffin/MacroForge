local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
local keepPrint = MF.Print
dofile(ROOT .. "/Core.lua")
MF.Print = keepPrint
local P = MF.Profiles
MF.db = { char = { backups = {}, profiles = {} }, profile = { maxBackups = 3, autoSwap = true } }
W.reset()
CreateMacro("A", 1, "a", true); CreateMacro("Acc", 1, "acc", false)
P:CreateBackup()                      -- manual #1
EditMacro(121, "A", 1, "a2"); EditMacro(1, "Acc", 1, "acc2")
DeleteMacro(1)
for i = 1, 7 do P:CreateBackup(true) end
P:CreateBackup(); P:CreateBackup()    -- 3 manual total, quota 3
local nA, nM = 0, 0
for _, b in ipairs(MF.db.char.backups) do if b.auto then nA = nA + 1 else nM = nM + 1 end end
assert(nA == 5 and nM == 3, nA .. "/" .. nM)
-- restore the oldest manual backup (the last entry): account macro must come back
local idx = #MF.db.char.backups
assert(not MF.db.char.backups[idx].auto)
P:RestoreBackup(idx)
assert(W.get(false, "Acc") and W.get(false, "Acc").body == "acc", "account not restored")
assert(W.get(true, "A").body == "a", "char not restored")
print("backup ok", W.printed[#W.printed])
