---------------------------------------------------
-- MacroForge — History (Ace3)
-- Macro revisions: every version of every macro, deleted ones included.
--
-- Revisions are keyed by macro name (duplicates get "#2", "#3" in slot
-- order), not by slot index: indexes shift whenever a macro is created or
-- deleted. Character macros live in db.char.revisions, account macros in
-- db.global.revisions.
--
-- The store is fed by diffing the macro list on UPDATE_MACROS, so edits made
-- anywhere (Blizzard's editor, other addons, set swaps) are recorded. A macro
-- that disappears keeps its versions and is flagged deleted: it can be
-- recreated from the trash.
---------------------------------------------------
local _, MF_NS = ...
local MF = LibStub("AceAddon-3.0"):GetAddon("MacroForge")
local L = LibStub("AceLocale-3.0"):GetLocale("MacroForge")
local AceGUI = LibStub("AceGUI-3.0")
local History = {}

local MAX_DELETED = 50
local SCOPES = { "character", "account" }

local ready = false      -- macros are only reliable once the client loaded them
local scanPending = false
local nextReason         -- reason tag for the next scan (e.g. a set swap)

---------------------------------------------------
-- Store helpers
---------------------------------------------------
function History:Store(scope)
    if scope == "account" then
        MF.db.global.revisions = MF.db.global.revisions or {}
        return MF.db.global.revisions
    end
    MF.db.char.revisions = MF.db.char.revisions or {}
    return MF.db.char.revisions
end

-- Current macros of a scope, each tagged with its revision key
function History:KeyedMacros(scope)
    local P = MF:GetModule("Profiles")
    local out, counts = {}, {}
    for _, m in ipairs(P:ReadMacros(scope)) do
        counts[m.name] = (counts[m.name] or 0) + 1
        m.key = counts[m.name] == 1 and m.name or (m.name .. "#" .. counts[m.name])
        table.insert(out, m)
    end
    return out
end

local function LastVersion(entry)
    return entry.versions[#entry.versions]
end

local function Record(entry, m, reason)
    local last = LastVersion(entry)
    if last and last.body == m.body and last.icon == m.icon and last.name == m.name then
        return
    end
    table.insert(entry.versions, {
        name = m.name, icon = m.icon, body = m.body,
        time = time(), reason = reason,
    })
    local maxHistory = MF.db.profile.maxHistory or 20
    while #entry.versions > maxHistory do
        table.remove(entry.versions, 1)
    end
end

local function PruneDeleted(store)
    local deleted = {}
    for key, entry in pairs(store) do
        if entry.deleted then table.insert(deleted, key) end
    end
    if #deleted <= MAX_DELETED then return end
    table.sort(deleted, function(a, b) return store[a].deleted > store[b].deleted end)
    for i = MAX_DELETED + 1, #deleted do
        store[deleted[i]] = nil
    end
end

---------------------------------------------------
-- Scan: diff the live macros against the store
---------------------------------------------------
function History:Scan(scope, reason)
    local store = self:Store(scope)
    local seen, appeared = {}, {}

    for _, m in ipairs(self:KeyedMacros(scope)) do
        seen[m.key] = true
        local entry = store[m.key]
        if entry then
            entry.deleted, entry.deletedReason = nil, nil
            Record(entry, m, reason)
        else
            table.insert(appeared, m)
        end
    end

    local vanished = {}
    for key, entry in pairs(store) do
        if not seen[key] and not entry.deleted then table.insert(vanished, key) end
    end

    -- A macro that vanished while another with the same body appeared was
    -- renamed: its versions follow the new name.
    for _, m in ipairs(appeared) do
        local from
        for i, key in ipairs(vanished) do
            local last = LastVersion(store[key])
            if last and last.body == m.body then from = i; break end
        end
        if from then
            local oldKey = table.remove(vanished, from)
            store[m.key], store[oldKey] = store[oldKey], nil
        else
            store[m.key] = { versions = {} }
        end
        Record(store[m.key], m, reason)
    end

    for _, key in ipairs(vanished) do
        store[key].deleted = time()
        store[key].deletedReason = reason
    end
    PruneDeleted(store)
end

function History:ScanAll(reason)
    if not ready or not MF.db then return end
    self:MigrateIndexHistory()
    for _, scope in ipairs(SCOPES) do self:Scan(scope, reason) end
end

-- Tags the versions recorded by the next scan (e.g. "set: Raid")
function History:SetNextReason(reason)
    nextReason = reason
end

function History:OnMacrosUpdated()
    ready = true
    if scanPending then return end
    scanPending = true
    -- A set swap fires one UPDATE_MACROS per write: scan once at the end
    C_Timer.After(0.5, function()
        scanPending = false
        local reason = nextReason
        nextReason = nil
        self:ScanAll(reason)
    end)
end

-- Called by the editor right before it overwrites a macro. The scan already
-- holds the current state; this only catches changes not yet scanned.
function History:SaveSnapshot()
    self:ScanAll()
end

---------------------------------------------------
-- Migration: v7.1 history was keyed by slot index
---------------------------------------------------
function History:MigrateIndexHistory()
    local old = MF.db.char.history
    if not old or not next(old) then return end
    local maxAccount = MF.Profiles.MAX_ACCOUNT_MACROS
    for indexKey, versions in pairs(old) do
        local index = tonumber(indexKey)
        local name = index and GetMacroInfo(index)
        if name and type(versions) == "table" then
            local scope = index > maxAccount and "character" or "account"
            local store = self:Store(scope)
            store[name] = store[name] or { versions = {} }
            local merged = {}
            for _, v in ipairs(versions) do
                table.insert(merged, {
                    name = v.name, icon = v.icon, body = v.body,
                    stamp = v.timestamp, reason = "v7",
                })
            end
            for _, v in ipairs(store[name].versions) do table.insert(merged, v) end
            store[name].versions = merged
        end
    end
    MF.db.char.history = nil
end

---------------------------------------------------
-- Queries
---------------------------------------------------
-- Revision key of a macro as returned by Profiles:Read*Macros
function History:KeyFor(macro)
    if not macro or not macro.scope then return nil end
    for _, m in ipairs(self:KeyedMacros(macro.scope)) do
        if m.index == macro.index then return m.key end
    end
    return macro.name
end

function History:GetVersions(scope, key)
    local entry = MF.db and self:Store(scope)[key]
    return entry and entry.versions or {}
end

function History:GetDeleted()
    local list = {}
    for _, scope in ipairs(SCOPES) do
        for key, entry in pairs(self:Store(scope)) do
            if entry.deleted and LastVersion(entry) then
                table.insert(list, { scope = scope, key = key, entry = entry })
            end
        end
    end
    table.sort(list, function(a, b) return a.entry.deleted > b.entry.deleted end)
    return list
end

function History:Purge()
    MF.db.char.revisions = {}
    MF.db.global.revisions = {}
    MF.db.char.history = nil
end

---------------------------------------------------
-- UI helpers
---------------------------------------------------
local function FormatTime(v)
    if v.time then return date("%Y-%m-%d %H:%M", v.time) end
    return v.stamp or "?"
end

local function ReasonTag(reason)
    if not reason then return "" end
    return "  " .. MF.C.grey .. "[" .. reason .. "]|r"
end

local function AddBodyPreview(grp, body)
    local An = MF:GetModule("Analyzer")
    local preview = AceGUI:Create("Label")
    preview:SetFullWidth(true)
    preview:SetFontObject(GameFontNormalSmall)
    preview:SetText((An and An:ColorizeBody(body) or body) .. "\n"
        .. MF.C.grey .. format(L["CHARS"], #body) .. "|r")
    grp:AddChild(preview)
end

---------------------------------------------------
-- Versions browser for one macro
---------------------------------------------------
function History:OpenVersions(scope, key)
    local versions = self:GetVersions(scope, key)
    if #versions == 0 then
        MF:Print(MF.C.grey .. L["NO_HISTORY"] .. "|r")
        return
    end

    local f = MF.Helpers:CreateDarkFrame("|cff00ccffMacroForge|r - " .. L["HISTORY"] .. " : " .. key, 520, 440, "Fill")
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    for i = #versions, 1, -1 do
        local v = versions[i]
        local grp = AceGUI:Create("InlineGroup")
        grp:SetFullWidth(true)
        grp:SetLayout("Flow")
        grp:SetTitle(MF.C.gold .. "#" .. i .. "|r  " .. MF.C.grey .. FormatTime(v) .. "|r  "
            .. MF.C.white .. (v.name or key) .. "|r" .. ReasonTag(v.reason)
            .. (i == #versions and ("  " .. MF.C.green .. L["VERSION_LATEST"] .. "|r") or ""))
        AddBodyPreview(grp, v.body or "")

        local btn = AceGUI:Create("Button")
        btn:SetText(L["VERSION_LOAD"])
        btn:SetWidth(160)
        btn:SetCallback("OnClick", function()
            local E = MF:GetModule("Editor")
            if not E then return end
            -- Load into the editor on the live macro if it still exists,
            -- otherwise as a new macro; the user saves explicitly.
            local live
            for _, m in ipairs(self:KeyedMacros(scope)) do
                if m.key == key then live = m; break end
            end
            if live then E:Open(live) else E:OpenNew(scope == "character") end
            C_Timer.After(0.1, function() E:LoadContent(v.name, v.body, v.icon) end)
            MF:Print(MF.C.green .. format(L["VERSION_RESTORED"], i) .. "|r")
            f:Release()
        end)
        grp:AddChild(btn)
        scroll:AddChild(grp)
    end
    f:Show()
end

-- Kept for callers passing a macro (editor, /mf history)
function History:OpenBrowser(macro)
    if type(macro) ~= "table" then
        MF:Print(MF.C.yellow .. L["OPEN_MACRO_FIRST"] .. "|r")
        return
    end
    self:ScanAll()
    self:OpenVersions(macro.scope, self:KeyFor(macro))
end

---------------------------------------------------
-- Trash: deleted macros, recreatable
---------------------------------------------------
function History:OpenTrash()
    self:ScanAll()
    local deleted = self:GetDeleted()
    if #deleted == 0 then
        MF:Print(MF.C.grey .. L["TRASH_EMPTY"] .. "|r")
        return
    end

    local f = MF.Helpers:CreateDarkFrame("|cff00ccffMacroForge|r - " .. L["TRASH"], 520, 460, "Fill")
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    for _, d in ipairs(deleted) do
        local last = LastVersion(d.entry)
        local grp = AceGUI:Create("InlineGroup")
        grp:SetFullWidth(true)
        grp:SetLayout("Flow")
        grp:SetTitle(MF.C.white .. d.key .. "|r  "
            .. MF.C.cyan .. (d.scope == "character" and L["SCOPE_CHAR"] or L["SCOPE_ACCOUNT"]) .. "|r  "
            .. MF.C.grey .. format(L["TRASH_DELETED_AT"], date("%Y-%m-%d %H:%M", d.entry.deleted)) .. "|r"
            .. ReasonTag(d.entry.deletedReason))
        AddBodyPreview(grp, last.body or "")

        local btnRecreate = AceGUI:Create("Button")
        btnRecreate:SetText(L["TRASH_RECREATE"])
        btnRecreate:SetWidth(130)
        btnRecreate:SetCallback("OnClick", function()
            local P = MF:GetModule("Profiles")
            if P then P:CreateNewMacro(last.name, last.icon, last.body, d.scope == "character") end
            local UI = MF:GetModule("UI")
            if UI then C_Timer.After(0.3, function() UI:Refresh() end) end
            f:Release()
        end)
        grp:AddChild(btnRecreate)

        local btnVersions = AceGUI:Create("Button")
        btnVersions:SetText(format(L["TRASH_VERSIONS"], #d.entry.versions))
        btnVersions:SetWidth(130)
        btnVersions:SetCallback("OnClick", function()
            f:Release()
            self:OpenVersions(d.scope, d.key)
        end)
        grp:AddChild(btnVersions)

        scroll:AddChild(grp)
    end
    f:Show()
end

function History:OnInitialize()
    MF:RegisterMessage("MF_MACROS_UPDATED", function() self:OnMacrosUpdated() end)
end

MF:RegisterModule("History", History)
