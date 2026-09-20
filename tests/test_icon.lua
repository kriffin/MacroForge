local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Helpers.lua")
dofile(ROOT .. "/Profiles.lua")
local H, P = MF.Helpers, MF.Profiles
local spellOf = {}
GetMacroSpell = function(i) return spellOf[i] end
C_Spell = { GetSpellTexture = function(id) return ({ [53] = 132090 })[id] end }
W.reset()
CreateMacro("Dyn", 132090, "#showtooltip\n/cast Backstab", true); spellOf[121] = 53   -- displays spell icon
CreateMacro("Custom", 777, "#showtooltip\n/cast Backstab", true); spellOf[122] = 53    -- custom icon kept
CreateMacro("NoShow", 132090, "/cast Backstab", true); spellOf[123] = 53              -- no #show: kept
CreateMacro("Q", 134400, "#showtooltip [combat] X", true)                            -- unresolved: "?" as is
local m = P:ReadCharacterMacros()
assert(m[1].icon == 134400, m[1].icon)
assert(m[2].icon == 777 and m[3].icon == 132090 and m[4].icon == 134400)
-- a swap writes "?" back, not the frozen spell icon
P:WriteCharacterMacros(m)
assert(W.get(true, "Dyn").icon == 132090, "unchanged macro must not be rewritten")
print("icon ok")
