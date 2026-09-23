local W = dofile(ROOT .. "/tests/wow_stub.lua")
dofile(ROOT .. "/Helpers.lua")
local H = MF.Helpers
local body = "#showtooltip\n\n/csatsequence Fireball, Pyroblast\n/cast Blink"
-- Line spans count blank lines, offsets are 0-based cursor positions
assert(select(1, H:LineSpan(body, 1)) == 0)
local s, e = H:LineSpan(body, 3)
assert(body:sub(s + 1, e) == "/csatsequence Fireball, Pyroblast", body:sub(s + 1, e))
s, e = H:LineSpan(body, 2); assert(s == e, "blank line")
assert(H:LineSpan(body, 5) == nil)
-- Command fix only touches the command on its line
local fixed = H:ApplyIssueFix(body, "Mage",
    { fixType = "command", line = 3, fixFrom = "/csatsequence", fix = "/castsequence" })
assert(fixed == "#showtooltip\n\n/castsequence Fireball, Pyroblast\n/cast Blink", fixed)
-- Indented line keeps its indentation
assert(H:ApplyIssueFix("  /csat X", "", { fixType = "command", line = 1, fixFrom = "/csat", fix = "/cast" }) == "  /cast X")
-- The text moved or was already fixed: no change
assert(H:ApplyIssueFix(fixed, "Mage", { fixType = "command", line = 3, fixFrom = "/csatsequence", fix = "/castsequence" }) == nil)
-- Name fix
local b2, n2 = H:ApplyIssueFix(body, "A very long macro name", { fixType = "name", line = 0, fix = "A very long macr" })
assert(b2 == body and n2 == "A very long macr")
-- No fix known
assert(H:ApplyIssueFix(body, "x", { fixType = "spell", line = 4 }) == nil)
-- End to end: the analyzer points at the real line and its fix applies
SLASH_CASTSEQUENCE1 = "/castsequence"; SLASH_CAST1 = "/cast"; SLASH_CATTEST1 = "/cat"
IsSecureCmd = function(c) return c == "/cast" or c == "/castsequence" end
dofile(ROOT .. "/Analyzer.lua")
local An = MF.modules.Analyzer
local iss
for _, i in ipairs(An:Analyze(body, "Mage").issues) do if i.fixType == "command" then iss = i end end
assert(iss and iss.line == 3 and iss.fixFrom == "/csatsequence" and iss.fix == "/castsequence",
    iss and (iss.line .. " " .. tostring(iss.fix)))
assert(H:ApplyIssueFix(body, "Mage", iss) == fixed)
-- Nothing close enough: no fix offered
for _, i in ipairs(An:Analyze("/zzzzzzzzzzzz x", "m").issues) do assert(not i.fix, i.fix) end
-- Lengths count characters: "Éclair mouseover" is 16, not 17
for _, i in ipairs(An:Analyze("/cast Blink", "Éclair mouseover").issues) do assert(i.fixType ~= "name", i.message) end
local long = An:Analyze("/cast Blink", "Éclair mouseover!").issues[1]
assert(long and long.fixType == "name" and long.fix == "Éclair mouseover", long and long.fix)
-- "/csat" is one edit from /cast and from another addon's /cat: /cast wins
local csat
for _, i in ipairs(An:Analyze("/csat Blink", "m").issues) do if i.fixType == "command" then csat = i end end
assert(csat and csat.fix == "/cast", csat and csat.fix)
print("fix ok")
