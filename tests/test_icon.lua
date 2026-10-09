local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Helpers.lua")
dofile(ROOT .. "/Profiles.lua")
local H, P = MF.Helpers, MF.Profiles
local spellOf = {}
GetMacroSpell = function(i) return spellOf[i] end
-- 53 Backstab, 5215 Prowl, 768 Cat Form: Prowl is a castsequence step, not what GetMacroSpell says
C_Spell = {
  GetSpellTexture = function(id) return ({ [53] = 132090, [5215] = 132089, [768] = 132115 })[id] end,
  GetSpellInfo = function(name)
    local byName = { ["Backstab"] = 53, ["Prowl"] = 5215, ["Cat Form"] = 768 }
    local id = byName[name]; return id and { spellID = id, iconID = C_Spell.GetSpellTexture(id) }
  end,
}
W.reset()
CreateMacro("Dyn", 132090, "#showtooltip\n/cast Backstab", true); spellOf[121] = 53   -- displays spell icon
CreateMacro("Custom", 777, "#showtooltip\n/cast Backstab", true); spellOf[122] = 53    -- custom icon kept
CreateMacro("NoShow", 132090, "/cast Backstab", true); spellOf[123] = 53              -- no #show: kept
CreateMacro("Q", 134400, "#showtooltip [combat] X", true)                            -- unresolved: "?" as is
-- shows a step GetMacroSpell does not name: still the icon of something the body casts
CreateMacro("Seq", 132089, "#showtooltip\n/castsequence [nomod] reset=4 Cat Form, Prowl\n/use [mod:shift] Bear Form", true); spellOf[125] = 768
local m = P:ReadCharacterMacros()
assert(m[1].icon == 134400, m[1].icon)
assert(m[2].icon == 777 and m[3].icon == 132090 and m[4].icon == 134400)
assert(m[5].icon == 134400, "castsequence step icon is dynamic: " .. tostring(m[5].icon))
assert(m[5].displayIcon == 132089)
-- a swap writes "?" back, not the frozen spell icon
P:WriteCharacterMacros(m)
assert(W.get(true, "Dyn").icon == 132090, "unchanged macro must not be rewritten")

-- A set saved while the macro showed its spell icon: the icon is not written
-- back (EditMacro gets nil and keeps what is stored)
W.get(true, "Dyn").icon = 134400
P:WriteCharacterMacros({ { name = "Dyn", icon = 132090, body = "#showtooltip\n/cast Backstab\n/say x" } })
assert(W.get(true, "Dyn").icon == 134400, "set apply froze the icon: " .. tostring(W.get(true, "Dyn").icon))
assert(W.get(true, "Dyn").body == "#showtooltip\n/cast Backstab\n/say x")
-- A set that really picks another icon writes it
P:WriteCharacterMacros({ { name = "Dyn", icon = 999, body = "#showtooltip\n/cast Backstab\n/say x" } })
assert(W.get(true, "Dyn").icon == 999)
-- A set that goes back to "?" writes it
P:WriteCharacterMacros({ { name = "Dyn", icon = 134400, body = "#showtooltip\n/cast Backstab\n/say x" } })
assert(W.get(true, "Dyn").icon == 134400)

-- Creating from a copy that carries the shown icon (Duplicate, a set, a revision): "?"
MF.Notify = MF.Notify or function() end
local idx = P:CreateNewMacro("Copy", 132090, "#showtooltip\n/cast Backstab", true)
assert(idx and W.get(true, "Copy").icon == 134400, tostring(W.get(true, "Copy").icon))
idx = P:CreateNewMacro("Plain", 132090, "/cast Backstab", true)
assert(idx and W.get(true, "Plain").icon == 132090, "no #show: the icon is a choice")

-- Body names: conditions, reset=, !, ; and , clauses, #show X
assert(H:StoredMacroIcon(nil, 132089, "#show [mod] !Prowl; Backstab") == 134400)
assert(H:StoredMacroIcon(nil, 132115, "/castrandom Cat Form, Prowl") == 132115, "no #show: kept")
assert(H:StoredMacroIcon(nil, 132115, "#showtooltip\n/castrandom Cat Form, Prowl") == 134400)
assert(H:StoredMacroIcon(nil, 555, "#showtooltip\n/cast Backstab") == 555, "an unrelated icon is a choice")
assert(H:StoredMacroIcon(nil, nil, "#showtooltip") == nil)
assert(H:HasShowTooltip("/cast X\n #show") and not H:HasShowTooltip("/cast #show"))
print("icon ok")
