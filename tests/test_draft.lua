local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Profiles.lua")
dofile(ROOT .. "/Helpers.lua")
local H, P = MF.Helpers, MF.Profiles
W.reset(); W.sorted = true
CreateMacro("Frost", 1, "/cast Frostbolt", true)
-- Draft left on Frost while it sat at index 121
local frost = P:ReadMacros("character")[1]
assert(frost.index == 121 and frost.name == "Frost")
local draft = { name = "Frost", body = "/cast Ice Lance", scope = "character", key = "Frost", index = 121 }
assert(H:DraftBelongsTo(draft, frost))
-- A macro sorted before it takes index 121: the draft still follows Frost
CreateMacro("Blink", 1, "/cast Blink", true)
local macros = P:ReadMacros("character")
local target = assert(H:DraftTarget(draft, macros), "draft lost its macro")
assert(target.name == "Frost" and target.index == 122, target.index)
for _, m in ipairs(macros) do
  if m.name == "Blink" then assert(not H:DraftBelongsTo(draft, m), "draft moved to Blink") end
end
-- Same name in the other scope is another macro
assert(not H:DraftBelongsTo(draft, { name = "Frost", scope = "account", index = 1 }))
-- A new macro's draft never lands on a saved one
assert(not H:DraftTarget({ isNew = true, name = "Frost", body = "x" }, macros))
-- Pre-7.4.0 drafts: index and name must both match
assert(H:DraftBelongsTo({ index = 122, name = "Frost" }, target))
assert(not H:DraftBelongsTo({ index = 121, name = "Frost" }, macros[1]))
print("draft ok")
