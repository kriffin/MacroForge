local W = dofile(ROOT .. "/tests/wow_stub.lua")
local names = { [6552] = "Pummel", [1776] = "Gouge" }  -- 408 missing: fallback
C_Spell = { GetSpellName = function(id) return names[id] end }
dofile(ROOT .. "/Templates.lua")
local T = MF.Templates
local b = T:ResolveBody("/cast [mod:shift] {spell:1776:Gouge}\n/cast {spell:408:Kidney Shot}; {ph:SORT}\n/cast {spell:6552:Pummel}")
assert(b == "/cast [mod:shift] Gouge\n/cast Kidney Shot; TPL_PH_SORT\n/cast Pummel", b)
-- every template body resolves with no marker left, and every spell marker has a fallback
local n = 0
local function walk(t) for _, v in pairs(t) do if type(v) == "table" then
  if v.body then n = n + 1; local r = T:ResolveBody(v.body); assert(not r:find("{"), r) end; walk(v) end end end
walk(T)
-- availability: a template shows only when all its spells exist in the client,
-- and WoW Forever templates never show on retail
local forever = T.CLASS_TEMPLATES.MAGE[#T.CLASS_TEMPLATES.MAGE]
assert(forever.flavor == "forever" and not T:IsAvailable(forever), "forever template hidden on retail")
assert(T:IsAvailable({ body = "/cast {spell:6552:Pummel}" }))
assert(not T:IsAvailable({ body = "/cast {spell:408:Kidney Shot}" }), "missing spell hides the template")
for _, t in ipairs(T:GetTemplatesForPlayer(nil, "WARRIOR")) do assert(T:IsAvailable(t)) end
print("templates ok, bodies:", n)
