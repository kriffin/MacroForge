local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Helpers.lua")
local H = MF.Helpers
-- Straight from a guide: no name line, the name comes from the spell
local m = assert(H:ParseMacroText("#showtooltip Kick\n/cast [@focus,harm,nodead][] Kick\n"))
assert(m.name == "Kick" and m.body == "#showtooltip Kick\n/cast [@focus,harm,nodead][] Kick", m.name)
assert(m.icon == H.DYNAMIC_ICON)
-- First spell of a conditional or a sequence
assert(H:ParseMacroText("/cast [mod:shift] Blink; Shimmer").name == "Blink")
assert(H:ParseMacroText("/castsequence reset=8 Fireball, Pyroblast").name == "Fireball")
-- A first line that is not a command is the name, Windows line ends
m = assert(H:ParseMacroText("  Burst  \r\n/use 13\r\n/cast Combustion"))
assert(m.name == "Burst" and m.body == "/use 13\n/cast Combustion", m.body)
-- No spell to name it after
assert(H:ParseMacroText("/reload").name == "Macro")
-- Not a macro / empty / too long
assert(not H:ParseMacroText("hello there"))
assert(not H:ParseMacroText("Title\nsome prose"))
assert(not H:ParseMacroText("   "))
assert(not H:ParseMacroText("/cast " .. string.rep("x", 260)))
print("import ok")
