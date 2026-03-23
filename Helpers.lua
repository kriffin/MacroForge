---------------------------------------------------
-- MacroForge — Helpers
-- Parsing, couleurs, utilitaires
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
MF.Helpers = {}

-- Severity markers (WoW-compatible, no unicode)
MF.Helpers.MOD_COLORS = {
    shift = "|cff33ccff", ctrl = "|cffff9933", alt = "|cffcc66ff",
}

MF.Helpers.SEV = {
    OK   = "|cff00ff88[OK]|r",
    WARN = "|cffffff33[!]|r",
    ERR  = "|cffff4444[X]|r",
    INFO = "|cff888888[i]|r",
    UNK  = "|cffffff33[?]|r",
}

function MF.Helpers:Print(msg)
    MF:Print(msg)
end

function MF.Helpers:ParseModifiers(body)
    if not body then return {} end
    local mods, found = {}, {}
    for mod in body:gmatch("%[.-mod:(%a+).-%]") do
        local l = mod:lower()
        if not found[l] then found[l] = true; table.insert(mods, l) end
    end
    return mods
end

function MF.Helpers:ParseTargeting(body)
    if not body then return {} end
    local targets, found = {}, {}
    for t in body:gmatch("@(%a+%d?)") do
        local l = t:lower()
        if not found[l] then found[l] = true; table.insert(targets, "@" .. l) end
    end
    return targets
end

function MF.Helpers:ParseShowTooltip(body)
    if not body then return nil end
    local s = body:match("#showtooltip%s+(.+)")
    return s and s:match("^%s*(.-)%s*$") or nil
end

function MF.Helpers:ParseSpells(body)
    if not body then return {} end
    local spells = {}
    for line in body:gmatch("[^\n]+") do
        local sp = line:match("/cast%s+%[.-%]%s*(.+)") or line:match("/cast%s+(.+)")
            or line:match("/use%s+%[.-%]%s*(.+)") or line:match("/use%s+(.+)")
        if sp then
            sp = sp:match("^%s*(.-)%s*$"):gsub("^%[.-%]%s*", "")
            if sp ~= "" and not sp:match("^%d+$") then table.insert(spells, sp) end
        end
    end
    return spells
end

function MF.Helpers:CondenseBody(body)
    if not body then return "" end
    local sp = self:ParseSpells(body)
    if #sp > 0 then
        local r = table.concat(sp, " > ")
        return #r > 50 and r:sub(1, 47) .. "..." or r
    end
    local first = body:match("^([^\n]+)") or body
    first = first:match("^%s*(.-)%s*$")
    return #first > 50 and first:sub(1, 47) .. "..." or first
end

function MF.Helpers:FormatModBadges(modifiers)
    if not modifiers or #modifiers == 0 then return "" end
    local b = {}
    for _, m in ipairs(modifiers) do
        local c = self.MOD_COLORS[m]
        if c then table.insert(b, c .. "[" .. m:upper() .. "]|r") end
    end
    return table.concat(b, " ")
end

---------------------------------------------------
-- AceGUI lazy accessor (replaces redundant G() across files)
---------------------------------------------------
local _AceGUI
function MF.Helpers:AceGUI()
    if not _AceGUI then _AceGUI = LibStub("AceGUI-3.0") end
    return _AceGUI
end

---------------------------------------------------
-- CreateDarkFrame — factory for dark-themed AceGUI Frames
-- Eliminates copy-pasted boilerplate across 10+ files
---------------------------------------------------
function MF.Helpers:CreateDarkFrame(title, width, height, layout)
    local gui = self:AceGUI()
    local f = gui:Create("Frame")
    f:SetTitle(title)
    f:SetWidth(width or 480)
    f:SetHeight(height or 350)
    f:SetLayout(layout or "Flow")
    f:SetCallback("OnClose", function(w) w:Release() end)
    -- Dark background
    local bg = f.frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    bg:SetPoint("TOPLEFT", f.content, -5, 5)
    bg:SetPoint("BOTTOMRIGHT", f.content, 5, -5)
    return f
end

---------------------------------------------------
-- Centralized Spellbook Cache
-- Used by Autocomplete and CommandPalette
---------------------------------------------------
local _spellbookCache = nil

function MF.Helpers:BuildSpellbookCache()
    if _spellbookCache then return _spellbookCache end
    _spellbookCache = {}

    if not C_SpellBook or not C_SpellBook.GetNumSpellBookSkillLines then
        return _spellbookCache
    end

    for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillInfo = C_SpellBook.GetSpellBookSkillLineInfo(tab)
        if skillInfo then
            for j = skillInfo.itemIndexOffset + 1, skillInfo.itemIndexOffset + skillInfo.numSpellBookItems do
                local spName = C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
                if spName and spName ~= "" then
                    local si = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spName)
                    table.insert(_spellbookCache, {
                        name = spName,
                        icon = si and si.iconID or 134400,
                        id = si and si.spellID,
                    })
                end
            end
        end
    end

    table.sort(_spellbookCache, function(a, b) return a.name < b.name end)
    return _spellbookCache
end

function MF.Helpers:InvalidateSpellbookCache()
    _spellbookCache = nil
end

function MF.Helpers:GetSpellbookSpells()
    return self:BuildSpellbookCache()
end

MF:RegisterModule("Helpers", MF.Helpers)
