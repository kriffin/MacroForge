---------------------------------------------------
-- MacroForge — Helpers
-- Parsing, couleurs, utilitaires
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
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
    -- Same line only: "#showtooltip\n/use Sap" shows no spell, it is automatic
    local s = body:match("#showtooltip[ \t]+([^\n]+)")
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
-- Macro validation for data coming from outside (AceComm, share codes)
---------------------------------------------------
MF.Helpers.MAX_NAME_CHARS = 16
MF.Helpers.MAX_BODY_CHARS = 255

local function Utf8Len(s)
    local _, n = s:gsub("[^\128-\191]", "")
    return n
end

-- First maxChars UTF-8 characters of s, never cutting a multibyte sequence
local function Utf8Truncate(s, maxChars)
    local count, cut = 0, #s
    for pos in s:gmatch("()[^\128-\191]") do
        count = count + 1
        if count > maxChars then cut = pos - 1; break end
    end
    return s:sub(1, cut)
end

-- Returns a clean {name, icon, body} copy, or nil + localized error.
-- The name loses control chars and "|" (no escape sequences in popups or
-- chat), the body is rejected past the macro limit instead of silently cut.
-- Macro limits count characters, not bytes: "É" is one of the 16
function MF.Helpers:CharLen(s) return Utf8Len(s or "") end
function MF.Helpers:TruncateChars(s, n) return Utf8Truncate(s or "", n) end

function MF.Helpers:SanitizeMacro(data)
    if type(data) ~= "table" or type(data.name) ~= "string" or type(data.body) ~= "string" then
        return nil, L["SHARE_BAD_STRUCT"]
    end
    local name = data.name:gsub("[%c|]", ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, L["SHARE_BAD_STRUCT"] end
    name = Utf8Truncate(name, self.MAX_NAME_CHARS)

    local body = data.body:gsub("\r\n?", "\n"):gsub("[%z\1-\9\11-\31]", "")
    if Utf8Len(body) > self.MAX_BODY_CHARS then
        return nil, format(L["SHARE_TOO_LONG"], Utf8Len(body), self.MAX_BODY_CHARS)
    end

    local icon = tonumber(data.icon)
    if not icon and type(data.icon) == "string" and #data.icon <= 256 and not data.icon:find("|", 1, true) then
        icon = data.icon
    end
    return { name = name, icon = icon or 134400, body = body }
end

---------------------------------------------------
-- Stored icon of a macro
-- A macro with the "?" icon (134400) and #show/#showtooltip displays the
-- icon of the spell or item it would use, and GetMacroInfo returns that
-- resolved icon, not "?". Writing it back (EditMacro/CreateMacro) freezes
-- the icon. When the returned icon is exactly the resolved one, the macro is
-- treated as dynamic and "?" is returned. (A custom icon identical to the
-- spell icon is also turned into "?": same look, now dynamic.)
---------------------------------------------------
MF.Helpers.DYNAMIC_ICON = 134400

local function ResolvedMacroTexture(index)
    local spellID = GetMacroSpell and GetMacroSpell(index)
    if spellID and C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then return tex end
    end
    local _, itemLink = GetMacroItem and GetMacroItem(index)
    local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
    if itemID and C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    end
    return nil
end

function MF.Helpers:StoredMacroIcon(index, icon, body)
    if not body or not (body:match("^%s*#show") or body:match("\n%s*#show")) then return icon end
    local resolved = ResolvedMacroTexture(index)
    if resolved and resolved == icon then return self.DYNAMIC_ICON end
    return icon
end

---------------------------------------------------
-- Put a macro on the cursor (drop it on an action bar)
---------------------------------------------------
function MF.Helpers:PickupMacro(index)
    if not index then return false end
    if InCombatLockdown() then
        MF:Print(MF.C.red .. L["COMBAT_BLOCKED"] .. "|r")
        return false
    end
    PickupMacro(index)
    local cursorType, cursorValue = GetCursorInfo()
    MF:Debug("drag", "pickup macro #%d -> cursor %s %s", index, tostring(cursorType), tostring(cursorValue))
    return cursorType == "macro"
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

-- Macro text pasted from a guide or a forum. A first line that is not a
-- command (# or /) is the name; otherwise the name comes from the spell
-- the macro shows or casts first.
function MF.Helpers:ParseMacroText(text)
    if type(text) ~= "string" then return nil, L["IMPORT_EMPTY"] end
    text = text:gsub("\r\n?", "\n"):match("^%s*(.-)%s*$")
    if text == "" then return nil, L["IMPORT_EMPTY"] end
    local name, body = text:match("^([^\n]*)\n(.*)$")
    if not name or name:match("^%s*[#/]") then
        name, body = nil, text
    end
    body = body:match("^%s*(.-)%s*$")
    if not body:match("^[#/]") then return nil, L["IMPORT_NOT_MACRO"] end
    if not name or name:match("^%s*$") then
        local spell = self:ParseShowTooltip(body) or self:ParseSpells(body)[1]
            or body:match("/cast%a+%s+%[.-%]%s*([^\n]+)") or body:match("/cast%a+%s+([^\n]+)")
        -- "/cast [mod:shift] A; B" or "reset=8 A, B": keep the first spell
        spell = spell and spell:gsub("^reset=%S+%s*", ""):match("^([^;,]+)")
        name = spell and spell:match("^%s*(.-)%s*$") or "Macro"
    end
    return self:SanitizeMacro({ name = name, body = body, icon = self.DYNAMIC_ICON })
end

-- Cursor offsets (0-based, as EditBox:SetCursorPosition wants them) of the
-- start and end of line n of body, or nil past the last line
function MF.Helpers:LineSpan(body, n)
    local pos, i = 0, 0
    for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
        i = i + 1
        if i == n then return pos, pos + #line end
        pos = pos + #line + 1
    end
end

-- Applies an analyzer fix: returns the new body and name, or nil when the
-- issue has no fix or the text it points at is gone
function MF.Helpers:ApplyIssueFix(body, name, issue)
    if not issue or not issue.fix then return nil end
    if issue.fixType == "name" then return body, issue.fix end
    if issue.fixType == "command" and issue.fixFrom then
        local s, e = self:LineSpan(body, issue.line)
        if not s then return nil end
        local line = body:sub(s + 1, e)
        local lead = line:match("^%s*")
        if line:sub(#lead + 1, #lead + #issue.fixFrom) ~= issue.fixFrom then return nil end
        line = lead .. issue.fix .. line:sub(#lead + #issue.fixFrom + 1)
        return body:sub(1, s) .. line .. body:sub(e + 1), name
    end
end

-- Playable classes of this client: { id, file, name }. GetClassInfo takes a
-- class ID and IDs have holes (WoW Forever: 1-5, 7-9 and 11, the druid),
-- so walking 1..GetNumClasses() misses classes.
function MF.Helpers:PlayableClasses()
    local ids = C_SpecializationInfo and C_SpecializationInfo.GetAllClassIDs and C_SpecializationInfo.GetAllClassIDs()
    if not ids then
        ids = {}
        for id = 1, 30 do ids[#ids + 1] = id end
    end
    local classes = {}
    for _, id in ipairs(ids) do
        local ok, name, file = pcall(GetClassInfo, id)
        if ok and file then table.insert(classes, { id = id, file = file, name = name }) end
    end
    return classes
end

-- Drafts: one unsaved edit per character. An existing macro's draft is keyed
-- by scope + saved name, not by index: WoW sorts macros by name, so an index
-- moves as soon as a macro is created or renamed.
function MF.Helpers:DraftBelongsTo(draft, macro)
    if not draft or not macro or draft.isNew then return false end
    if draft.scope then
        return draft.scope == macro.scope and draft.key == macro.name
    end
    -- Drafts saved before 7.4.0 only have the index and the edited name
    return draft.index == macro.index and draft.name == macro.name
end

-- The saved macro a draft belongs to, or nil (new macro, or gone)
function MF.Helpers:DraftTarget(draft, macros)
    for _, m in ipairs(macros or {}) do
        if self:DraftBelongsTo(draft, m) then return m end
    end
end

MF:RegisterModule("Helpers", MF.Helpers)
