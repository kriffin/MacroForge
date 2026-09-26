local W = dofile(ROOT .. "/tests/wow_stub.lua")
SLASH_CAST1 = "/cast"; SLASH_CASTSEQUENCE1 = "/castsequence"; SLASH_TARGET1 = "/cib"; SLASH_SAY1 = "/say"
IsSecureCmd = function(c) return c == "/cast" or c == "/castsequence" or c == "/cib" end
dofile(ROOT .. "/Analyzer.lua")
local An = MF.modules.Analyzer
local H = MF.Helpers
An:BuildCommandList()

-- line -> expected message key (nil: valid) and fixed line (nil: no safe fix)
local function check(line, key, fix)
    local msg, fixed = An:CheckSyntax(line)
    assert(msg == key, ("%q: message %s, expected %s"):format(line, tostring(msg), tostring(key)))
    assert(fixed == fix, ("%q: fix %q, expected %q"):format(line, tostring(fixed), tostring(fix)))
end

-- Valid lines stay untouched
check("/cast Frostbolt", nil)
check("/cast [@mouseover,help,nodead] Flash Heal; [help] Flash Heal", nil)
check("/cast [mod:shift] A; [combat][nocombat,mod] B; C", nil)
check("/cast [combat]Frostbolt", nil)
check("/cast [] Frostbolt", nil)
check("/cast [known:Fire Blast] Fire Blast", nil)
check("/castsequence [combat] reset=10 A, B, C", nil)
check("/cast [@focus, harm, nodead] Polymorph", nil)
-- The reported case: conditions typed after the argument
check("/cib Lardeur[@mouseover]", "SYNTAX_COND_AFTER", "/cib [@mouseover] Lardeur")
check("/cib Lardeur [@mouseover] ", "SYNTAX_COND_AFTER", "/cib [@mouseover] Lardeur ")
check("/cast Frostbolt [combat][mod]", "SYNTAX_COND_AFTER", "/cast [combat][mod] Frostbolt")
-- Only the broken clause moves
check("/cast [mod] A; B [combat]", "SYNTAX_COND_AFTER", "/cast [mod] A; [combat] B")
-- castsequence: reset= before the conditions
check("/castsequence reset=5 [combat] A, B", "SYNTAX_COND_AFTER", "/castsequence [combat] reset=5 A, B")
-- Missing ; between two clauses
check("/cast [combat] A [nocombat] B", "SYNTAX_MISSING_SEMICOLON", "/cast [combat] A; [nocombat] B")
-- Several at once: every ; comes back in one fix
check("/cast [combat] A [mod] B [nocombat] C", "SYNTAX_MISSING_SEMICOLON", "/cast [combat] A; [mod] B; [nocombat] C")
-- Conditions on both sides of the argument: no guess
check("/cast [combat] A [mod]", "SYNTAX_COND_AFTER", nil)
-- Spaces instead of commas
check("/cast [combat mod:shift] A", "SYNTAX_SPACE_IN_COND", "/cast [combat,mod:shift] A")
check("/cast [@focus harm] Polymorph", "SYNTAX_SPACE_IN_COND", "/cast [@focus,harm] Polymorph")
-- ...but a spaced argument or an unknown word is left alone
check("/cast [combat and mod] A", "SYNTAX_SPACE_IN_COND", nil)
check("/cast [nocombat; mod] A", "SYNTAX_SEMICOLON_IN_COND", nil)
-- Unclosed [
check("/cast [combat Frostbolt", "SYNTAX_UNCLOSED", "/cast [combat] Frostbolt")
check("/cast [@focus,harm Polymorph; Frostbolt", "SYNTAX_UNCLOSED", "/cast [@focus,harm] Polymorph; Frostbolt")
check("/cast [combat, mod:alt Frostbolt", "SYNTAX_UNCLOSED", "/cast [combat, mod:alt] Frostbolt")
check("/cast [known:Fire Blast Fire Blast", "SYNTAX_UNCLOSED", nil)
check("/cast [Frostbolt", "SYNTAX_UNCLOSED", nil)
-- Unclosed, then after the fix the conditions sit after the argument: both fixed at once
check("/cib Lardeur[@mouseover", "SYNTAX_UNCLOSED", "/cib [@mouseover] Lardeur")
-- Stray ]
check("/cast combat] Frostbolt", "SYNTAX_STRAY_CLOSE", "/cast [combat] Frostbolt")
check("/cast [combat]] Frostbolt", "SYNTAX_STRAY_CLOSE", "/cast [combat] Frostbolt")
check("/cast Frostbolt]", "SYNTAX_STRAY_CLOSE", "/cast Frostbolt")
check("/cast [mod] A; nocombat] B", "SYNTAX_STRAY_CLOSE", "/cast [mod] A; [nocombat] B")
-- Nested
check("/cast [[combat] Frostbolt", "SYNTAX_NESTED", "/cast [combat] Frostbolt")
check("/cast [combat [mod] Frostbolt", "SYNTAX_NESTED", nil)

-- Analyze: one ERR per broken line, with the fix; non-option commands ignored
local r = An:Analyze("/say hi [there\n/cib Lardeur[@mouseover]", "m")
local found
for _, i in ipairs(r.issues) do
    assert(i.line ~= 1, "/say is no option command: " .. i.message)
    if i.fixType == "line" then found = i end
end
assert(found and found.severity == "ERR" and found.line == 2 and found.fix == "/cib [@mouseover] Lardeur")
local body = H:ApplyIssueFix("/say hi [there\n/cib Lardeur[@mouseover]", "m", found)
assert(body == "/say hi [there\n/cib [@mouseover] Lardeur", body)
-- The line changed since: no fix
assert(H:ApplyIssueFix("/cib Other[@mouseover]", "m", found) == nil)

-- Builder insertion: at the start of the cursor's clause
local function ins(b, cursor, cond)
    local at, pre = H:ConditionInsertPos(b, cursor)
    return b:sub(1, at) .. pre .. cond .. " " .. b:sub(at + 1)
end
assert(ins("/cib Lardeur", 12, "[@mouseover]") == "/cib [@mouseover] Lardeur")
assert(ins("/cast A; B", 10, "[mod]") == "/cast A; [mod] B")
assert(ins("/cast A;B", 9, "[mod]") == "/cast A; [mod] B")
assert(ins("/cast [a;b] A", 13, "[mod]") == "/cast [mod] [a;b] A")
assert(ins("#showtooltip\n/cast", 18, "[mod]") == "#showtooltip\n/cast [mod] ")
assert(ins("", 0, "[mod]") == "[mod] ")
assert(ins("/cast X\n/use Y", 14, "[combat]") == "/cast X\n/use [combat] Y")
print("syntax ok")
