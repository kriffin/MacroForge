-- Spellbook cache and spell checks on a WoW Forever client, where every
-- known rank of a spell is a spellbook entry of its own
local W = dofile(ROOT .. "/tests/wow_stub.lua")
function GetBuildInfo() return "1.60.1", "1", "", 16001 end
Enum = {
    SpellBookSpellBank = { Player = 0 },
    SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 },
}
local S, FUTURE, FLYOUT = 1, 2, 4
local BOOK = {
    { name = "Earth Shock", subName = "Rank 1", spellID = 8042, iconID = 101, itemType = S },
    { name = "Lightning Bolt", subName = "Rank 1", spellID = 403, iconID = 102, itemType = S },
    { name = "Earth Shock", subName = "Rank 2", spellID = 8044, iconID = 101, itemType = S },
    { name = "Earth Shock", subName = "Rank 3", spellID = 8045, iconID = 101, itemType = S },
    { name = "Healing Wave", subName = "Rank 1", spellID = 331, iconID = 103, itemType = S },
    { name = "Portals", subName = "", iconID = 104, itemType = FLYOUT },
    { name = "Elemental Mastery", subName = "", spellID = 16166, iconID = 105, itemType = FUTURE },
    { name = "Ancestral Knowledge", subName = "Passive", spellID = 16254, iconID = 106, itemType = S, isPassive = true },
    -- A second skill line listing a spell of the first one
    { name = "Healing Wave", subName = "Rank 1", spellID = 331, iconID = 103, itemType = S },
}
local lines = { { itemIndexOffset = 0, numSpellBookItems = 8 }, { itemIndexOffset = 8, numSpellBookItems = 1 } }
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return #lines end,
    GetSpellBookSkillLineInfo = function(i) return lines[i] end,
    GetSpellBookItemInfo = function(j) return BOOK[j] end,
}
-- The spell API answers the highest known rank for a plain name and
-- nothing for "Name(Rank n)", like the client
C_Spell = {
    GetSpellInfo = function(n)
        local best
        for _, e in ipairs(BOOK) do
            if e.spellID and (e.spellID == n or e.name:lower() == tostring(n):lower()) then best = e end
        end
        return best and { name = best.name, spellID = best.spellID, iconID = best.iconID }
    end,
    GetSpellTexture = function(n) local i = C_Spell.GetSpellInfo(n); return i and i.iconID end,
}
local H = MF.Helpers

local function texts(list)
    local t = {}
    for _, e in ipairs(list) do t[#t + 1] = e.text end
    return table.concat(t, "|")
end
local spells = H:GetSpellbookSpells()
-- Plain name first (the highest rank), then the ranks; flyouts, unlearned
-- and passive entries out; a spell listed twice shows once
assert(texts(spells) == "Earth Shock|Earth Shock(Rank 1)|Earth Shock(Rank 2)|Healing Wave|Lightning Bolt", texts(spells))
assert(spells[1].id == 8045 and spells[1].sub == "Rank 3" and spells[1].name == "Earth Shock")
assert(spells[2].id == 8042 and spells[2].sub == "Rank 1")
assert(spells[4].text == "Healing Wave" and spells[4].sub == "Rank 1", "one rank: plain name")
-- What a macro types finds the entry, whatever the case or spacing
assert(H:FindSpellbookSpell("earth shock(rank 1)").id == 8042)
assert(H:FindSpellbookSpell("Earth Shock (Rank 2)").id == 8044)
assert(H:FindSpellbookSpell("Earth Shock(Rank 3)").id == 8045)
assert(H:FindSpellbookSpell(" Earth Shock ").id == 8045)
assert(H:FindSpellbookSpell("Healing Wave(Rank 1)").id == 331)
assert(H:FindSpellbookSpell("Portals") == nil and H:FindSpellbookSpell("Elemental Mastery") == nil)
assert(H:FindSpellbookSpell("Earth Shock(Rank 9)") == nil)

-- The analyzer verifies a rank through the spellbook
SLASH_CAST1 = "/cast"; SLASH_USE1 = "/use"; SLASH_CASTSEQUENCE1 = "/castsequence"; SLASH_STOPCASTING1 = "/stopcasting"
IsSecureCmd = function(c) return c == "/cast" or c == "/use" or c == "/castsequence" end
dofile(ROOT .. "/Analyzer.lua")
local An = MF.modules.Analyzer
An:BuildCommandList()
local c = An:CheckSpell("Earth Shock(Rank 1)")
assert(c and c.type == "spell" and c.id == 8042 and c.icon == 101 and c.name == "Earth Shock(Rank 1)")
assert(An:CheckSpell("Earth Shock").id == 8045)
local res = An:Analyze("#showtooltip\n/stopcasting\n/use [@mouseover,harm,nodead][]Earth Shock(Rank 1)", "ES")
assert(#res.issues == 0, res.issues[1] and res.issues[1].message)
assert(#res.spells == 1 and res.spells[1].name == "Earth Shock(Rank 1)")
res = An:Analyze("/cast Earth Shock(Rank 9)", "x")
assert(#res.issues == 1 and res.issues[1].message == "ANALYZER_UNVERIFIED", "a rank not known stays unverified")

-- Colouring: every character of the line comes back (the overlay sits on
-- the typed text), castsequence steps and reset= read one by one
local SYN = An.SYN
local function plain(s) return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local line = "/castsequence reset=10 Earth Shock(Rank 1), Lightning Bolt ; Healing Wave "
local col = An:ColorizeLine(line)
assert(plain(col) == line, plain(col))
assert(col:find(SYN.seq .. "reset=10" .. SYN.r, 1, true), col)
assert(col:find(SYN.spell .. "Earth Shock(Rank 1)" .. SYN.r, 1, true), col)
assert(col:find(SYN.spell .. "Lightning Bolt" .. SYN.r, 1, true), col)
assert(col:find(SYN.spell .. "Healing Wave" .. SYN.r, 1, true), col)
assert(plain(An:ColorizeLine("/cast A ; B")) == "/cast A ; B")
assert(plain(An:ColorizeLine("/cast [mod:shift] Earth Shock(Rank 1); Earth Shock")) == "/cast [mod:shift] Earth Shock(Rank 1); Earth Shock")
assert(An:ColorizeLine("/cast Nope"):find(SYN.unk .. "Nope", 1, true))

-- Learning Rank 4: the caches are dropped, the plain name moves up
H:InvalidateSpellbookCache(); An:InvalidateSpellCache()
BOOK[#BOOK + 1] = { name = "Earth Shock", subName = "Rank 4", spellID = 8046, iconID = 101, itemType = S }
lines[2].numSpellBookItems = 2
assert(H:FindSpellbookSpell("Earth Shock").id == 8046)
assert(H:FindSpellbookSpell("Earth Shock(Rank 3)").id == 8045)
assert(An:CheckSpell("Earth Shock").id == 8046)
assert(texts(H:GetSpellbookSpells()):find("Earth Shock|Earth Shock(Rank 1)|Earth Shock(Rank 2)|Earth Shock(Rank 3)|", 1, true))

-- A pasted macro is named after its spell, rank left out
local m = H:ParseMacroText("#showtooltip\n/use [@mouseover,harm,nodead][]Earth Shock(Rank 1)")
assert(m.name == "Earth Shock", m.name)
assert(H:ParseMacroText("/cast Frostbolt").name == "Frostbolt")

-- An empty spellbook (client not ready) is not remembered
H:InvalidateSpellbookCache()
lines = {}
assert(#H:GetSpellbookSpells() == 0)
lines = { { itemIndexOffset = 0, numSpellBookItems = 1 } }
assert(#H:GetSpellbookSpells() == 1)

-- Without GetSpellBookItemInfo (older API): name + subName, IDs from the spell API
H:InvalidateSpellbookCache()
lines = { { itemIndexOffset = 0, numSpellBookItems = 4 } }
C_SpellBook.GetSpellBookItemInfo = nil
C_SpellBook.GetSpellBookItemName = function(j) return BOOK[j].name, BOOK[j].subName end
spells = H:GetSpellbookSpells()
assert(texts(spells) == "Earth Shock|Earth Shock(Rank 1)|Earth Shock(Rank 2)|Lightning Bolt", texts(spells))
assert(H:FindSpellbookSpell("Earth Shock(Rank 1)").id == 8046, "plain-name lookup: the API's highest rank")
print("ok spellbook: ranks, filters, lookup, colouring")
